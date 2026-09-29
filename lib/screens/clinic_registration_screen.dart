import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/clinic_store.dart';
import 'application_status_screen.dart';

class ClinicRegistrationScreen extends StatefulWidget {
  const ClinicRegistrationScreen({super.key});

  @override
  State<ClinicRegistrationScreen> createState() => _ClinicRegistrationScreenState();
}

class _ClinicRegistrationScreenState extends State<ClinicRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isFetchingGps = false;

  // Clinic Controllers
  final _clinicNameController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _specialityController = TextEditingController(text: 'General Medicine');
  final _operatingHoursController = TextEditingController(text: '09:00 AM - 08:00 PM');
  final _latController = TextEditingController(text: '19.0760');
  final _lngController = TextEditingController(text: '72.8777');

  // Doctor Controllers
  final _doctorNameController = TextEditingController();
  final _doctorPhoneController = TextEditingController();
  final _doctorSpecialityController = TextEditingController(text: 'General Physician');
  final _qualificationController = TextEditingController();
  final _regNumController = TextEditingController();
  int _avgConsultationMinutes = 10;

  bool _isSubmitting = false;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final clinicStore = Provider.of<ClinicStore>(context, listen: false);

    final app = await clinicStore.submitApplication(
      clinicName: _clinicNameController.text.trim(),
      clinicPhone: _clinicPhoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: double.tryParse(_latController.text.trim()) ?? 19.0760,
      longitude: double.tryParse(_lngController.text.trim()) ?? 72.8777,
      speciality: _specialityController.text.trim(),
      operatingHours: _operatingHoursController.text.trim(),
      doctorName: _doctorNameController.text.trim(),
      doctorPhone: _doctorPhoneController.text.trim(),
      doctorSpeciality: _doctorSpecialityController.text.trim(),
      doctorQualification: _qualificationController.text.trim(),
      doctorRegNum: _regNumController.text.trim(),
      avgConsultationMinutes: _avgConsultationMinutes,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationStatusScreen(applicationId: app.id),
        ),
      );
    }
  }

  void _fetchCurrentGpsLocation() async {
    setState(() => _isFetchingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services disabled. Please enable GPS.')),
          );
        }
        setState(() => _isFetchingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          setState(() => _isFetchingGps = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
        _isFetchingGps = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 GPS Location fetched! Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}'),
            backgroundColor: const Color(0xFF0F766E),
          ),
        );
      }
    } catch (e) {
      setState(() => _isFetchingGps = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location fetch error: $e')),
        );
      }
    }
  }

  void _showAddressPickerModal() {
    final presetAddresses = [
      {
        'title': '102 Healthcare Avenue, Block B',
        'address': '102 Healthcare Avenue, Block B',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'pincode': '400001',
        'lat': '19.0760',
        'lng': '72.8777',
      },
      {
        'title': '55 Park Street, Near Metro Station',
        'address': '55 Park Street, Near Metro Station',
        'city': 'Delhi',
        'state': 'Delhi',
        'pincode': '110001',
        'lat': '28.6139',
        'lng': '77.2090',
      },
      {
        'title': '78 Civil Lines, MG Road',
        'address': '78 Civil Lines, MG Road',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'pincode': '560001',
        'lat': '12.9716',
        'lng': '77.5946',
      },
      {
        'title': '12 Sector 18, Commercial Hub',
        'address': '12 Sector 18, Commercial Hub',
        'city': 'Noida',
        'state': 'Uttar Pradesh',
        'pincode': '201301',
        'lat': '28.5708',
        'lng': '77.3261',
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pick Address / Preset Landmark',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: presetAddresses.length,
                  itemBuilder: (ctx, index) {
                    final item = presetAddresses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF0F766E),
                          child: Icon(Icons.location_city_rounded, color: Colors.white, size: 20),
                        ),
                        title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['city']}, ${item['state']} - ${item['pincode']}'),
                        onTap: () {
                          setState(() {
                            _addressController.text = item['address']!;
                            _cityController.text = item['city']!;
                            _stateController.text = item['state']!;
                            _pincodeController.text = item['pincode']!;
                            _latController.text = item['lat']!;
                            _lngController.text = item['lng']!;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected address: ${item['title']}'),
                              backgroundColor: const Color(0xFF0F766E),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CareSeva 2 Clinic Registration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'View Application Status',
            icon: const Icon(Icons.assignment_turned_in_rounded),
            onPressed: () {
              final store = Provider.of<ClinicStore>(context, listen: false);
              if (store.currentApplication != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicationStatusScreen(
                      applicationId: store.currentApplication!.id,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No existing application found.')),
                );
              }
            },
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting clinic registration application...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep == 0) {
                    if (_clinicNameController.text.isEmpty ||
                        _clinicPhoneController.text.isEmpty ||
                        _addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required clinic fields')),
                      );
                      return;
                    }
                    setState(() => _currentStep = 1);
                  } else if (_currentStep == 1) {
                    if (_doctorNameController.text.isEmpty || _doctorPhoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill required doctor information')),
                      );
                      return;
                    }
                    setState(() => _currentStep = 2);
                  } else {
                    _submitForm();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  }
                },
                steps: [
                  // Step 1: Clinic Information
                  Step(
                    title: Text('Clinic Information', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Basic location & contact details'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.editing,
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _clinicNameController,
                          decoration: const InputDecoration(
                            labelText: 'Clinic Name *',
                            prefixIcon: Icon(Icons.local_hospital_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clinicPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Clinic Phone Number *',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address (Optional)',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _specialityController,
                          decoration: const InputDecoration(
                            labelText: 'Clinic Speciality / Department *',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _operatingHoursController,
                          decoration: const InputDecoration(
                            labelText: 'Operating Hours *',
                            prefixIcon: Icon(Icons.access_time_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  foregroundColor: const Color(0xFF0F766E),
                                  side: const BorderSide(color: Color(0xFF0F766E)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _showAddressPickerModal,
                                icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                                label: const Text('PICK FROM APP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: const Color(0xFF0284C7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _isFetchingGps ? null : _fetchCurrentGpsLocation,
                                icon: _isFetchingGps
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.my_location_rounded, size: 18),
                                label: const Text('FETCH GPS LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Full Address *',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(
                                  labelText: 'State *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _pincodeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Pincode *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
                                decoration: const InputDecoration(
                                  labelText: 'Latitude',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _lngController,
                                decoration: const InputDecoration(
                                  labelText: 'Longitude',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Step 2: Doctor Information
                  Step(
                    title: Text('Primary Doctor Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Doctor qualification & registration'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.editing,
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _doctorNameController,
                          decoration: const InputDecoration(
                            labelText: 'Doctor Full Name *',
                            prefixIcon: Icon(Icons.person_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _doctorPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Doctor Phone Number *',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _doctorSpecialityController,
                          decoration: const InputDecoration(
                            labelText: 'Doctor Speciality *',
                            prefixIcon: Icon(Icons.medical_information_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _qualificationController,
                          decoration: const InputDecoration(
                            labelText: 'Qualification (e.g. MBBS, BDS, MD)',
                            prefixIcon: Icon(Icons.school_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _regNumController,
                          decoration: const InputDecoration(
                            labelText: 'Medical Registration No. / License',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _avgConsultationMinutes,
                          decoration: const InputDecoration(
                            labelText: 'Average Consultation Time Per Patient',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          items: [5, 10, 15, 20, 30].map((t) {
                            return DropdownMenuItem(value: t, child: Text('$t Minutes'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _avgConsultationMinutes = val);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Step 3: Review & Submit
                  Step(
                    title: Text('Review & Submit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Confirm application details'),
                    isActive: _currentStep >= 2,
                    content: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0284C7)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7)),
                              SizedBox(width: 8),
                              Text(
                                'Important Notice',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Upon submission, your clinic registration will be reviewed by the CareSeva 2 Admin team. '
                            'Once approved, a unique alpha-numeric Clinic ID (e.g. CS-7K82P) will be generated for public patient discovery.',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
