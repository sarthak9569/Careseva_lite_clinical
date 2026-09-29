import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clinic_application.dart';
import 'api_service.dart';

class ClinicStore extends ChangeNotifier {
  static const String _kApplicationsKey = 'cs_clinic_applications';
  static const String _kCurrentAppIdKey = 'cs_current_app_id';

  List<ClinicApplication> _allApplications = [];
  ClinicApplication? _currentApplication;

  List<ClinicApplication> get allApplications => _allApplications;
  ClinicApplication? get currentApplication => _currentApplication;

  ClinicStore() {
    _initFirestoreAndLoadData();
  }

  Future<void> _initFirestoreAndLoadData() async {
    await _loadLocalData();

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      final firestore = FirebaseFirestore.instance;
      debugPrint('[ClinicStore Live] Connected to Firestore project: ${firestore.app.options.projectId}');

      firestore.collection('clinicApplications').snapshots().listen((snapshot) {
        final List<ClinicApplication> remoteApps = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return ClinicApplication.fromJson(data);
        }).toList();

        // Merge remote apps into local list, keeping locally submitted pending apps intact
        for (var remoteApp in remoteApps) {
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
        _saveData();
        notifyListeners();
      }, onError: (e) {
        debugPrint('[ClinicStore Firestore Error] Applications stream: $e');
      });
    } catch (e) {
      debugPrint('[ClinicStore] Local mode: $e');
    }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final appsRaw = prefs.getString(_kApplicationsKey);
    if (appsRaw != null) {
      final List decoded = jsonDecode(appsRaw);
      _allApplications = decoded.map((e) => ClinicApplication.fromJson(e)).toList();
      // Filter out legacy hardcoded dummy APP-1001 if user submitted real applications
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

  /// Submit a new Clinic Application
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

    // Remove old dummy seed app if present
    _allApplications.removeWhere((a) => a.id == 'APP-1001');

    _allApplications.insert(0, app);
    _currentApplication = app;

    // Send to Railway backend API
    try {
      await ApiService.submitApplication(app.toJson());
    } catch (e) {
      debugPrint('[ClinicStore] ApiService Submit Error: $e');
    }

    // Write to Cloud Firestore collection
    try {
      await FirebaseFirestore.instance.collection('clinicApplications').doc(newId).set(app.toJson());
    } catch (e) {
      debugPrint('[ClinicStore] Firestore Submit Application Error: $e');
    }

    await _saveData();
    notifyListeners();
    return app;
  }

  /// Refresh Application Status
  Future<void> refreshStatus() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('clinicApplications').doc(_currentApplication?.id).get();
      if (doc.exists && doc.data() != null) {
        _currentApplication = ClinicApplication.fromJson(doc.data()!);
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('[ClinicStore] Firestore Refresh Error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final appsRaw = prefs.getString(_kApplicationsKey);
    if (appsRaw != null) {
      final List decoded = jsonDecode(appsRaw);
      _allApplications = decoded.map((e) => ClinicApplication.fromJson(e)).toList();
      if (_currentApplication != null) {
        final updated = _allApplications.firstWhere(
          (a) => a.id == _currentApplication!.id,
          orElse: () => _currentApplication!,
        );
        _currentApplication = updated;
      }
    }
    notifyListeners();
  }
}
