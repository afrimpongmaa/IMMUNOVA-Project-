import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immunova/Screens/educational_resources.dart';
import 'package:immunova/Screens/patient_records.dart';
import 'package:immunova/Screens/profile.dart';
import 'package:immunova/Screens/setting_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // added
import 'package:immunova/widgets/success_modal.dart'; // added
import 'package:immunova/services/sync_service.dart';

class ImmunizationRecord {
  String? vaccineId; // selected vaccine_id from Supabase
  // ...existing code...
  final TextEditingController dateController = TextEditingController();
  String? dose; // '1st' | '2nd' | '3rd' | '4th' | '5th' | 'Booster'
  void dispose() {
    // ...existing code...
    dateController.dispose();
  }
}

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});
  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
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

  // Vaccines state
  List<Map<String, String>> _vaccines = [];
  bool _loadingVaccines = true;
  String? _vaccinesError;

  // Dose options
  final List<String> _doseOptions = const [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    'Booster',
  ];

  // NEW: entry modes and existing patients
  final List<String> _entryModes = const ['Existing patient', 'New patient'];
  String _entryMode = 'Existing patient';
  List<Map<String, String>> _doctorPatients = [];
  bool _loadingPatients = true;
  String? _patientsError;
  String? _selectedExistingPatientId;

  int selectedBottomNavIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadVaccines();
    _loadDoctorPatients(); // NEW
  }

  Future<void> _loadVaccines() async {
    setState(() {
      _loadingVaccines = true;
      _vaccinesError = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('vaccines')
          .select('id, vaccine_name')
          .order('vaccine_name');
      final list = (res as List)
          .map(
            (e) => {
              'id': e['id'] as String,
              'name': e['vaccine_name'] as String,
            },
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _vaccines = list;
        _loadingVaccines = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _vaccinesError = 'Failed to load vaccines';
        _loadingVaccines = false;
      });
    }
  }

  // NEW: load existing patients for this doctor
  Future<void> _loadDoctorPatients() async {
    setState(() {
      _loadingPatients = true;
      _patientsError = null;
    });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        setState(() {
          _doctorPatients = [];
          _loadingPatients = false;
        });
        return;
      }
      final res = await Supabase.instance.client
          .from('patient_records')
          .select('patient_id, name')
          .eq('doc_id', uid)
          .order('updated_at', ascending: false);
      final list = (res as List)
          .map(
            (e) => {
              'id': e['patient_id'] as String,
              'name': (e['name'] as String).trim(),
            },
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _doctorPatients = list;
        _loadingPatients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _patientsError = 'Failed to load patients';
        _loadingPatients = false;
      });
    }
  }

  // Helper: map UI gender to DB expected 'M'/'F'
  String? _mapGender(String? gender) {
    if (gender == null) return null;
    if (gender.toLowerCase().startsWith('m')) return 'M';
    if (gender.toLowerCase().startsWith('f')) return 'F';
    return null; // invalid for schema
  }

  // Helper: parse DD/MM/YYYY or YYYY-MM-DD to YYYY-MM-DD
  String? _normalizeDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final ddmmyyyy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final m = ddmmyyyy.firstMatch(s);
    if (m != null) {
      final d = m.group(1)!;
      final mo = m.group(2)!;
      final y = m.group(3)!;
      return '$y-$mo-$d';
    }
    // Try direct ISO parse
    try {
      final dt = DateTime.parse(s);
      return dt.toIso8601String().split('T').first;
    } catch (_) {
      return null;
    }
  }

  // Date helpers
  Future<void> _pickDate(
    TextEditingController controller, {
    DateTime? initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final parsed = _tryParseIsoDate(controller.text);
    final now = DateTime.now();
    final init = initialDate ?? parsed ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: init.isBefore(firstDate) || init.isAfter(lastDate)
          ? firstDate
          : init,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4ECDC4)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = _formatIsoDate(picked);
    }
  }

  DateTime? _tryParseIsoDate(String v) {
    try {
      if (v.trim().isEmpty) return null;
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }

  String _formatIsoDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF4ECDC4),
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'ADD PATIENT',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D3748),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorProfileScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44B3A3)],
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: Icon(Icons.person, color: Color(0xFF4ECDC4), size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NEW: Action chooser
              _buildSectionCard(
                title: 'ACTION',
                icon: Icons.swap_horiz,
                children: [
                  DropdownButtonFormField<String>(
                    value: _entryMode,
                    items: _entryModes
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _entryMode = v!;
                    }),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(
                          color: Color(0xFF4ECDC4),
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_entryMode == 'Existing patient')
                    _buildExistingPatientDropdown(), // NEW
                ],
              ),

              const SizedBox(height: 24),

              // Show new-patient form only when needed (collapsed by default via mode)
              if (_entryMode == 'New patient') ...[
                _buildSectionCard(
                  title: 'PERSONAL DETAILS',
                  icon: Icons.person_outline,
                  children: [
                    _buildTextField(
                      controller: _patientNameController,
                      label: 'Patient Name',
                      hint: 'Enter full name',
                      prefixIcon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _dobController,
                      label: 'Date of Birth',
                      hint: 'YYYY-MM-DD',
                      suffixIcon: Icons.calendar_today,
                      prefixIcon: Icons.cake,
                      readOnly: true,
                      onTap: () => _pickDate(
                        _dobController,
                        firstDate: DateTime(1900, 1, 1),
                        lastDate: DateTime.now(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Gender',
                      value: _selectedGender,
                      items: _genderOptions,
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'CONTACT INFORMATION',
                  icon: Icons.contact_phone_outlined,
                  children: [
                    _buildTextField(
                      controller: _emergencyContactController,
                      label: 'Parent or Guardian\'s Name',
                      hint: 'Enter guardian name',
                      prefixIcon: Icons.family_restroom,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _guardianNumberController,
                      label: 'Guardian\'s Phone Number',
                      hint: '+233 000 000 000',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              _buildSectionCard(
                title: 'IMMUNIZATION RECORDS',
                icon: Icons.vaccines_outlined,
                children: [
                  // ...existing immunization rows...
                  ..._immunizationRecords.asMap().entries.map((entry) {
                    final index = entry.key;
                    final record = entry.value;
                    return Column(
                      children: [
                        _buildImmunizationInputCard(record, index),
                        if (index < _immunizationRecords.length - 1)
                          const SizedBox(height: 16),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  _buildAddButton(),
                ],
              ),

              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // NEW: Existing patient dropdown (doctor-scoped)
  Widget _buildExistingPatientDropdown() {
    if (_loadingPatients) {
      return Row(
        children: const [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading patients...'),
        ],
      );
    }
    if (_patientsError != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _patientsError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: _loadDoctorPatients,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select patient',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedExistingPatientId,
          isExpanded: true,
          items: _doctorPatients
              .map(
                (p) =>
                    DropdownMenuItem(value: p['id'], child: Text(p['name']!)),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedExistingPatientId = v),
          validator: (v) =>
              (_entryMode == 'Existing patient' && (v == null || v.isEmpty))
              ? 'Select a patient'
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF4ECDC4), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              Icons.people,
              color: Color(0xFF4ECDC4),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF4ECDC4), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? suffixIcon,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    bool readOnly = false, // added
    VoidCallback? onTap, // added
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: readOnly
                ? TextInputType.none
                : keyboardType, // prevent keyboard for dates
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: const Color(0xFF4ECDC4), size: 20)
                  : null,
              suffixIcon: suffixIcon != null
                  ? Icon(suffixIcon, color: Colors.grey[400], size: 20)
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4ECDC4),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
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
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4ECDC4), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF4ECDC4).withOpacity(0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _addImmunizationRecord,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF4ECDC4),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Immunization Record',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4ECDC4),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ); // close outer Container
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44B3A3)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _savePatientRecord();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Save Patient Record',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildImmunizationInputCard(ImmunizationRecord record, int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4ECDC4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Immunization Record ${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              if (_immunizationRecords.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _removeImmunizationRecord(index),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Vaccine dropdown
          _buildVaccineDropdown(record),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: record.dateController,
                  label: 'Date Due',
                  hint: 'YYYY-MM-DD',
                  suffixIcon: Icons.calendar_today,
                  prefixIcon: Icons.event,
                  readOnly: true,
                  onTap: () => _pickDate(
                    record.dateController,
                    firstDate: DateTime(2000, 1, 1),
                    lastDate: DateTime(2100, 12, 31),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildDoseDropdown(record)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineDropdown(ImmunizationRecord record) {
    if (_loadingVaccines) {
      return Row(
        children: const [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading vaccines...'),
        ],
      );
    }
    if (_vaccinesError != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_vaccinesError!, style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: _loadVaccines, child: const Text('Retry')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vaccine',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: record.vaccineId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF4ECDC4), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              Icons.vaccines,
              color: Color(0xFF4ECDC4),
              size: 20,
            ),
          ),
          items: _vaccines
              .map(
                (v) => DropdownMenuItem<String>(
                  value: v['id'],
                  child: Text(v['name']!),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => record.vaccineId = val),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Select a vaccine' : null,
        ),
      ],
    );
  }

  Widget _buildDoseDropdown(ImmunizationRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dose',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: record.dose,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF4ECDC4), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              Icons.medical_services,
              color: Color(0xFF4ECDC4),
              size: 20,
            ),
          ),
          items: _doseOptions
              .map((d) => DropdownMenuItem<String>(value: d, child: Text(d)))
              .toList(),
          onChanged: (val) => setState(() => record.dose = val),
          validator: (v) => (v == null || v.isEmpty) ? 'Select a dose' : null,
        ),
      ],
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

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(
              128,
              128,
              128,
              0.1,
            ), // was Colors.grey.withOpacity(0.1)
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

  // Save handler now supports both entry modes
  Future<void> _savePatientRecord() async {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to save'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Build immunizations (require vaccine + dose; date may be required by your validator)
    final List<Map<String, dynamic>> immunizations = [];
    for (final rec in _immunizationRecords) {
      if (rec.vaccineId == null || (rec.dose == null || rec.dose!.isEmpty))
        continue;
      final dueIso = rec.dateController.text.trim().isEmpty
          ? null
          : _normalizeDate(rec.dateController.text.trim());
      immunizations.add({
        'vaccine_id': rec.vaccineId,
        'date_due': dueIso,
        'dose': rec.dose,
        'status': 'pending',
      });
    }

    if (immunizations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one immunization record'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

  try {
      String? patientId;

      if (_entryMode == 'Existing patient') {
        // Validate chosen patient
        if (_selectedExistingPatientId == null ||
            _selectedExistingPatientId!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a patient'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        patientId = _selectedExistingPatientId;

        // Insert immunizations for existing patient
        await supa
            .from('immunization_records')
            .insert(
              immunizations
                  .map((m) => {'patient_id': patientId, ...m})
                  .toList(),
            );
      } else {
        // Validate new patient fields
        final name = _patientNameController.text.trim();
        final dobIso = _normalizeDate(_dobController.text);
        final genderChar = _mapGender(_selectedGender);
        if (name.isEmpty || dobIso == null || genderChar == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete name, valid DOB, and gender.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Create patient first
        final patientRow = await supa
            .from('patient_records')
            .insert({
              'doc_id': uid,
              'name': name,
              'dob': dobIso,
              'gender': genderChar,
              'guardian_name': _emergencyContactController.text.trim(),
              'guardian_num': _guardianNumberController.text.trim(),
              'emergency_contact_number':
                  _guardianNumberController.text.trim().isEmpty
                  ? null
                  : _guardianNumberController.text.trim(),
            })
            .select('patient_id')
            .single();

        patientId = patientRow['patient_id'] as String?;
        if (patientId == null) throw Exception('Failed to create patient');

        await supa
            .from('immunization_records')
            .insert(
              immunizations
                  .map((m) => {'patient_id': patientId, ...m})
                  .toList(),
            );
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SuccessModal(
          title: 'Record Saved',
          message: _entryMode == 'Existing patient'
              ? 'Immunization records have been added.'
              : 'Patient and immunization records have been saved.',
          onClose: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PatientRecords()),
            );
          },
        ),
      );
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      // Likely offline: enqueue for background sync
      try {
        if (_entryMode == 'Existing patient') {
          await SyncService.instance.enqueue(
            'immunization_records',
            'insert_for_patient',
            {
              'patient_id': _selectedExistingPatientId,
              'records': immunizations,
            },
          );
        } else {
          final name = _patientNameController.text.trim();
          final dobIso = _normalizeDate(_dobController.text);
          final genderChar = _mapGender(_selectedGender);
          await SyncService.instance.enqueue(
            'patient_records',
            'create_with_immunizations',
            {
              'patient': {
                'doc_id': uid,
                'name': name,
                'dob': dobIso,
                'gender': genderChar,
                'guardian_name': _emergencyContactController.text.trim(),
                'guardian_num': _guardianNumberController.text.trim(),
                'emergency_contact_number':
                    _guardianNumberController.text.trim().isEmpty
                        ? null
                        : _guardianNumberController.text.trim(),
              },
              'immunizations': immunizations,
            },
          );
        }

        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessModal(
            title: 'Saved locally',
            message:
                'You seem offline. Changes will sync automatically when back online.',
            onClose: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PatientRecords()),
              );
            },
          ),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ...existing code (build methods, dropdowns, etc.)...
}
