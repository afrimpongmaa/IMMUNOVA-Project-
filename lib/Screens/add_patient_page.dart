import 'package:flutter/material.dart';
import 'package:immunova/Screens/educational_resources.dart';
import 'package:immunova/Screens/patient_records.dart';
import 'package:immunova/Screens/profile.dart';
import 'package:immunova/Screens/setting_page.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/patient.dart';
import '../models/immunization.dart';
import '../providers/user_session.dart';

class ImmunizationRecord {
  final TextEditingController vaccineNameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController doseController = TextEditingController();

  void dispose() {
    vaccineNameController.dispose();
    dateController.dispose();
    doseController.dispose();
  }
}

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _guardianNumberController =
      TextEditingController();

  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  List<ImmunizationRecord> _immunizationRecords = [
    ImmunizationRecord(),
    ImmunizationRecord(),
  ];

  int selectedBottomNavIndex = 2;

  // Add this method for showing the date picker
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate =
        DateTime.now().subtract(const Duration(days: 365 * 5));
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Add method for immunization date picker
  Future<void> _selectImmunizationDate(BuildContext context, int index) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _immunizationRecords[index].dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    final doctorName = session.displayName ?? 'Doctor';
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ADD PATIENT • ${doctorName}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorProfileScreen(),
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Color(0xFF4ECDC4),
                radius: 18,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('PERSONAL DETAILS'),
              SizedBox(height: 16),
              _buildTextField(
                controller: _patientNameController,
                label: 'Patient Name',
                hint: '',
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _dobController,
                label: 'Date of Birth',
                hint: 'YYYY-MM-DD',
                suffixIcon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 16),
              _buildDropdownField(
                label: 'Gender',
                value: _selectedGender,
                items: _genderOptions,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              SizedBox(height: 32),
              _buildSectionHeader('CONTACT INFORMATION'),
              SizedBox(height: 16),
              _buildTextField(
                controller: _emergencyContactController,
                label: 'Parent or Guardian\'s Name',
                hint: '',
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _guardianNumberController,
                label: 'Guardian\'s Phone Number',
                hint: '',
              ),
              SizedBox(height: 32),
              _buildSectionHeader('IMMUNIZATION SCHEDULE'),
              SizedBox(height: 16),
              ..._immunizationRecords.asMap().entries.map((entry) {
                int index = entry.key;
                ImmunizationRecord record = entry.value;
                return Column(
                  children: [
                    _buildImmunizationInputCard(record, index),
                    if (index < _immunizationRecords.length - 1)
                      SizedBox(height: 16),
                  ],
                );
              }).toList(),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _addImmunizationRecord,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF4ECDC4)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Color(0xFF4ECDC4)),
                      SizedBox(width: 8),
                      Text(
                        'Add Immunization Record',
                        style: TextStyle(
                          color: Color(0xFF4ECDC4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _savePatientRecord();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Patient Record',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.people, 'Patients', 0),
          _buildBottomNavItem(Icons.description_outlined, 'Resources', 1),
          _buildBottomNavItem(Icons.person_add_outlined, 'Add Patient', 2),
          _buildBottomNavItem(Icons.settings_outlined, 'Settings', 3),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    bool isActive = selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () => _handleBottomNavTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Color(0xFF4ECDC4) : Colors.grey[400],
              size: 22,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Color(0xFF4ECDC4) : Colors.grey[400],
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (selectedBottomNavIndex == index) return;
    setState(() {
      selectedBottomNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientRecords()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EducationalResourcesPage(),
          ),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
    }
  }

  void _addImmunizationRecord() {
    setState(() {
      _immunizationRecords.add(ImmunizationRecord());
    });
  }

  void _removeImmunizationRecord(int index) {
    if (_immunizationRecords.length > 1) {
      setState(() {
        _immunizationRecords[index].dispose();
        _immunizationRecords.removeAt(index);
      });
    }
  }

  void _savePatientRecord() async {
    try {
      final currentLocalId =
          Provider.of<UserSession>(context, listen: false).localId;
      if (currentLocalId == null) {
        throw Exception('No signed-in user. Please sign in first.');
      }

      final patient = Patient(
        patientId: DateTime.now().millisecondsSinceEpoch.toString(),
        docId: currentLocalId,
        name: _patientNameController.text,
        dob: DateTime.parse(_dobController.text),
        gender: _selectedGender ?? 'M',
        guardianName: _emergencyContactController.text,
        guardianNum: _guardianNumberController.text,
      );

      final patientLocalId = await _db.insert('patients', patient.toMap());

      // Save immunization records and track latest immunization date
      DateTime? latest;
      for (var record in _immunizationRecords) {
        if (record.vaccineNameController.text.isNotEmpty &&
            record.dateController.text.isNotEmpty) {
          DateTime? parsedDate;
          try {
            parsedDate = DateTime.parse(record.dateController.text);
          } catch (e) {
            parsedDate = null;
          }
          if (parsedDate != null) {
            if (latest == null || parsedDate.isAfter(latest)) {
              latest = parsedDate;
            }

            final immunization = Immunization(
              patientId: patientLocalId,
              vaccineId: 1, // Replace with actual vaccine ID mapping
              dateTaken: parsedDate,
              dose: record.doseController.text,
              status: 'Immunized',
            );
            await _db.insert('immunizations', immunization.toMap());
          }
        }
      }

      // Update patient's last_time_immunized if we found a date
      if (latest != null) {
        final updatedPatientMap = patient.toMap();
        updatedPatientMap['last_time_immunized'] = latest.toIso8601String();
        await _db.update('patients', updatedPatientMap, patientLocalId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Patient record saved successfully!'),
          backgroundColor: Color(0xFF4ECDC4),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PatientRecords()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving patient record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: Colors.grey[400], size: 20)
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF4ECDC4), width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            // Only validate date format for DOB field
            if (label == 'Date of Birth') {
              try {
                DateTime.parse(value);
              } catch (_) {
                return 'Enter a valid date (YYYY-MM-DD)';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF4ECDC4), width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select an option';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImmunizationInputCard(ImmunizationRecord record, int index) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Immunization Record ${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Spacer(),
              if (_immunizationRecords.length > 1)
                IconButton(
                  onPressed: () => _removeImmunizationRecord(index),
                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: record.vaccineNameController,
            label: 'Vaccine Name',
            hint: 'e.g., BCG, Hepatitis B, DPT',
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: record.dateController,
                  label: 'Date Taken',
                  hint: 'YYYY-MM-DD',
                  suffixIcon: Icons.calendar_today,
                  readOnly: true,
                  onTap: () => _selectImmunizationDate(context, index),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: record.doseController,
                  label: 'Dose',
                  hint: 'e.g., 1st, 2nd, Booster',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _dobController.dispose();
    _emergencyContactController.dispose();
    _guardianNumberController.dispose();
    for (var record in _immunizationRecords) {
      record.dispose();
    }
    super.dispose();
  }
}
