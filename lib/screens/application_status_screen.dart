import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/clinic_application.dart';
import '../services/clinic_store.dart';
import 'clinic_registration_screen.dart';

class ApplicationStatusScreen extends StatefulWidget {
  final String applicationId;

  const ApplicationStatusScreen({super.key, required this.applicationId});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  bool _isRefreshing = false;

  void _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final store = Provider.of<ClinicStore>(context, listen: false);
    await store.refreshStatus();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final clinicStore = Provider.of<ClinicStore>(context);
    final app = clinicStore.allApplications.firstWhere(
      (a) => a.id == widget.applicationId,
      orElse: () => clinicStore.currentApplication ??
          ClinicApplication(
            id: widget.applicationId,
            clinicName: 'Unknown Clinic',
            clinicPhone: '',
            email: '',
            address: '',
            city: '',
            state: '',
            pincode: '',
            latitude: 0,
            longitude: 0,
            speciality: '',
            operatingHours: '',
            doctorName: '',
            doctorPhone: '',
            doctorSpeciality: '',
            doctorQualification: '',
            doctorRegNum: '',
            submittedAt: DateTime.now(),
          ),
    );

    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Application Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Refresh Status',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Status Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getStatusColor(app.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getStatusColor(app.status), width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(_getStatusIcon(app.status), size: 56, color: _getStatusColor(app.status)),
                  const SizedBox(height: 12),
                  Text(
                    app.status.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(app.status),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Application ID: ${app.id}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getStatusMessage(app.status),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),

                  // Display Clinic ID prominently if approved!
                  if (app.status == ApplicationStatus.approved && app.assignedClinicId != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'YOUR UNIQUE CLINIC ID',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            app.assignedClinicId!,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted Details',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    _buildRow('Clinic Name', app.clinicName),
                    _buildRow('Phone', app.clinicPhone),
                    _buildRow('Speciality', app.speciality),
                    _buildRow('Doctor Name', app.doctorName),
                    _buildRow('Doctor Phone', app.doctorPhone),
                    _buildRow('Submitted On', dateFormat.format(app.submittedAt)),
                    if (app.rejectionReason != null) _buildRow('Rejection Reason', app.rejectionReason!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ClinicRegistrationScreen()),
                );
              },
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Submit Another Clinic Application'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.suspended:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.hourglass_top_rounded;
      case ApplicationStatus.approved:
        return Icons.verified_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
      case ApplicationStatus.suspended:
        return Icons.pause_circle_filled_rounded;
    }
  }

  String _getStatusMessage(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Your registration is currently being reviewed by the CareSeva Admin team. You will be assigned a Clinic ID upon approval.';
      case ApplicationStatus.approved:
        return 'Congratulations! Your clinic is approved and now discoverable on CareSeva 2 using your unique Clinic ID.';
      case ApplicationStatus.rejected:
        return 'Your application was rejected. Please review the details or contact admin support.';
      case ApplicationStatus.suspended:
        return 'Your clinic is currently suspended. Please contact admin for reactivation.';
    }
  }
}
