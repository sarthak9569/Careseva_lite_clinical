import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clinic_application.dart';
import 'api_service.dart';

class ClinicStore extends ChangeNotifier {
  static const String _kApplicationsKey = 'cs_clinic_applications';
  static const String _kCurrentAppIdKey = 'cs_current_app_id';

  List<ClinicApplication> _allApplications = [];
  ClinicApplication? _currentApplication;
  Timer? _pollingTimer;

  List<ClinicApplication> get allApplications => _allApplications;
  ClinicApplication? get currentApplication => _currentApplication;

  ClinicStore() {
    _initAndLoadData();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAndLoadData() async {
    await _loadLocalData();
    await _fetchRemoteApplications();

    // Periodic real-time status polling from Railway MongoDB Backend (Every 3s)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchRemoteApplications();
    });
  }

  Future<void> _fetchRemoteApplications() async {
    try {
      final remoteData = await ApiService.getApplications();
      if (remoteData.isNotEmpty) {
        final List<ClinicApplication> parsed = remoteData
            .map((e) => ClinicApplication.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        for (var remoteApp in parsed) {
          final idx = _allApplications.indexWhere((a) => a.id == remoteApp.id);
          if (idx != -1) {
            _allApplications[idx] = remoteApp;
          } else {
            _allApplications.add(remoteApp);
          }
        }
        _allApplications.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

        if (_currentApplication != null) {
          final updated = _allApplications.firstWhere(
            (a) => a.id == _currentApplication!.id,
            orElse: () => _currentApplication!,
          );
          _currentApplication = updated;
        }
        await _saveData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ClinicStore] Railway API Polling Notice: $e');
    }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final appsRaw = prefs.getString(_kApplicationsKey);
    if (appsRaw != null) {
      final List decoded = jsonDecode(appsRaw);
      _allApplications = decoded.map((e) => ClinicApplication.fromJson(e)).toList();
      if (_allApplications.length > 1) {
        _allApplications.removeWhere((a) => a.id == 'APP-1001');
      }
    }

    final currentId = prefs.getString(_kCurrentAppIdKey);
    if (currentId != null) {
      final match = _allApplications.where((a) => a.id == currentId);
      if (match.isNotEmpty) {
        _currentApplication = match.first;
      }
    } else if (_allApplications.isNotEmpty) {
      _currentApplication = _allApplications.first;
    }

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kApplicationsKey,
      jsonEncode(_allApplications.map((e) => e.toJson()).toList()),
    );
    if (_currentApplication != null) {
      await prefs.setString(_kCurrentAppIdKey, _currentApplication!.id);
    }
  }

  /// Submit a new Clinic Application directly to Railway MongoDB Backend
  Future<ClinicApplication> submitApplication({
    required String clinicName,
    required String clinicPhone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required double latitude,
    required double longitude,
    required String speciality,
    required String operatingHours,
    required String doctorName,
    required String doctorPhone,
    required String doctorSpeciality,
    required String doctorQualification,
    required String doctorRegNum,
    required int avgConsultationMinutes,
  }) async {
    final newId = 'APP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final app = ClinicApplication(
      id: newId,
      clinicName: clinicName,
      clinicPhone: clinicPhone,
      email: email,
      address: address,
      city: city,
      state: state,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      speciality: speciality,
      operatingHours: operatingHours,
      doctorName: doctorName,
      doctorPhone: doctorPhone,
      doctorSpeciality: doctorSpeciality,
      doctorQualification: doctorQualification,
      doctorRegNum: doctorRegNum,
      avgConsultationMinutes: avgConsultationMinutes,
      status: ApplicationStatus.pending,
      submittedAt: DateTime.now(),
    );

    _allApplications.removeWhere((a) => a.id == 'APP-1001');

    _allApplications.insert(0, app);
    _currentApplication = app;

    // Direct HTTP POST to Railway FastAPI MongoDB Backend
    try {
      await ApiService.submitApplication(app.toJson());
    } catch (e) {
      debugPrint('[ClinicStore] ApiService Submit Error: $e');
    }

    await _saveData();
    notifyListeners();
    return app;
  }

  /// Refresh Application Status from Railway MongoDB Backend
  Future<void> refreshStatus() async {
    await _fetchRemoteApplications();
  }
}
