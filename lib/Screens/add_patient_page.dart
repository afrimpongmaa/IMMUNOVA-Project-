import 'package:flutter/material.dart';

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
  // ignore: library_private_types_in_public_api
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _guardianNumberController =
      TextEditingController();

  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  // Controllers for immunization fields
  List<ImmunizationRecord> _immunizationRecords = [
    ImmunizationRecord(),
    ImmunizationRecord(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ADD PATIENT',
          style: TextStyle(
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
            child: CircleAvatar(
              backgroundColor: Color(0xFF4ECDC4),
              radius: 18,
              child: Icon(Icons.person, color: Colors.white, size: 20),
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
              // Personal Details Section
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
                hint: '',
                suffixIcon: Icons.calendar_today,
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

              // Contact Information Section
              _buildSectionHeader('CONTACT INFORMATION'),
              SizedBox(height: 16),

              _buildTextField(
                controller: _emergencyContactController,
                label: 'Emergency Contact Number',
                hint: '',
              ),
              SizedBox(height: 16),

              _buildTextField(
                controller: _guardianNumberController,
                label: '''Guardian's Phone Number''',
                hint: '',
              ),

              SizedBox(height: 32),

              // Immunization Schedule Section
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

              // Add more immunization record button
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

              // Save Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Handle save patient record
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

          // Vaccine Name Field
          _buildTextField(
            controller: record.vaccineNameController,
            label: 'Vaccine Name',
            hint: 'e.g., BCG, Hepatitis B, DPT',
          ),
          SizedBox(height: 16),

          // Date and Dose in a Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: record.dateController,
                  label: 'Date Taken',
                  hint: 'MM/DD/YYYY',
                  suffixIcon: Icons.calendar_today,
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

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
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
          _buildBottomNavItem(Icons.people, 'Patients', false),
          _buildBottomNavItem(Icons.description, 'Resources', false),
          _buildBottomNavItem(Icons.person_add, 'Add Patient', true),
          _buildBottomNavItem(Icons.settings, 'Settings', false),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? Color(0xFF4ECDC4) : Colors.grey[400],
          size: 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Color(0xFF4ECDC4) : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  void _savePatientRecord() {
    // Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Patient record saved successfully!'),
        backgroundColor: Color(0xFF4ECDC4),
      ),
    );
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _dobController.dispose();
    _emergencyContactController.dispose();
    _guardianNumberController.dispose();

    // Dispose immunization record controllers
    for (var record in _immunizationRecords) {
      record.dispose();
    }

    super.dispose();
  }
}
