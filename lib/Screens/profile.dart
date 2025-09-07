import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:immunova/Screens/reminders_page.dart';
import 'package:immunova/repositories/user_bio_repository.dart';
import 'package:immunova/services/storage_service.dart';
import 'package:immunova/widgets/success_modal.dart';
import 'package:immunova/services/sync_service.dart';
// no path import needed

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _repo = UserBioRepository();
  final _storage = StorageService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _bio; // user_bio row
  int _patientsImmunized = 0;
  int _totalPatients = 0;
  List<Map<String, dynamic>> _hospitals = [];

  static const List<String> _specializations = [
    'Pediatrics',
    'General Practice',
    'Internal Medicine',
    'Obstetrics and Gynecology',
    'Public Health',
    'Family Medicine',
    'Dermatology',
    'Emergency Medicine',
    'Surgery',
    'Orthopedics',
    'Psychiatry',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bioF = _repo.getMyBio();
      final statsF = _repo.getMyStats();
      final hospitalsF = Supabase.instance.client
          .from('hospitals')
          .select('id,name')
          .order('name');
      final bio = await bioF;
      final stats = await statsF;
      final hospitals = await hospitalsF as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _bio = bio ?? {};
        _patientsImmunized = stats['patients_immunized'] ?? 0;
        _totalPatients = stats['total_patients'] ?? 0;
        _hospitals = hospitals.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile';
        _loading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _EditProfileSheet(
          bio: _bio ?? {},
          onSaved: (values) async {
            try {
              // Try online first
              await _repo.upsertMyBio(values);
              await _load();
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => SuccessModal(
                    title: 'Profile updated',
                    message: 'Your details have been saved successfully.',
                    onClose: () => Navigator.of(context).pop(),
                  ),
                );
              }
            } catch (_) {
              // If failed (likely offline), enqueue for sync
              await SyncService.instance.enqueue('user_bio', 'upsert', values);
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => SuccessModal(
                    title: 'Saved locally',
                    message: 'You seem offline. Changes will sync automatically when back online.',
                    onClose: () => Navigator.of(context).pop(),
                  ),
                );
              }
            }
          },
          onUploadAvatar: (Uint8List bytes, String originalFileName) async {
            final uid = Supabase.instance.client.auth.currentUser?.id;
            if (uid == null) return null;
            final url = await _storage.uploadAvatar(
              userId: uid,
              bytes: bytes,
              originalFileName: originalFileName,
            );
            return url;
          },
          specializations: _specializations,
          hospitals: _hospitals,
        );
      },
    );
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
          'PROFILE',
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
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF4ECDC4)),
              onPressed: _editProfile,
              tooltip: 'Edit profile',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF4ECDC4),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RemindersPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  _buildProfileCard(_bio ?? {}),
                  const SizedBox(height: 32),
                  _buildInfoSection(_bio ?? {}, hospitals: _hospitals),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Patients\nImmunized',
                          '$_patientsImmunized',
                          Icons.people_outline,
                          const Color(0xFF4ECDC4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Total\nPatients',
                          '$_totalPatients',
                          Icons.groups_2_outlined,
                          const Color(0xFF44B3A3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> bio;
  final Future<void> Function(Map<String, dynamic> values) onSaved;
  final Future<String?> Function(Uint8List bytes, String originalFileName)
  onUploadAvatar;
  final List<String> specializations;
  final List<Map<String, dynamic>> hospitals;

  const _EditProfileSheet({
    required this.bio,
    required this.onSaved,
    required this.onUploadAvatar,
    required this.specializations,
    required this.hospitals,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioCtl;
  late TextEditingController _yearsCtl;
  late TextEditingController _otherSpecCtl;
  final Set<String> _selectedDays = <String>{};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String? _avatarUrl;
  String? _specialization;
  String? _hospitalId;
  List<Map<String, String>> _languages = [];
  List<Map<String, String>> _certifications = [];

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.bio['avatar_url'] as String?;
    _hospitalId = widget.bio['hospital_id'] as String?;
    _bioCtl = TextEditingController(text: widget.bio['bio'] as String? ?? '');
    _yearsCtl = TextEditingController(
      text: (widget.bio['years_experience']?.toString()) ?? '',
    );
    _specialization = widget.bio['specialization'] as String?;
    _otherSpecCtl = TextEditingController();
    final wh = widget.bio['working_hours'] as Map<String, dynamic>?;
    final days = (wh?['days'] as List?)?.whereType<String>().toList() ?? [];
    _selectedDays.addAll(days);
    String? start = wh?['start']?.toString();
    String? end = wh?['end']?.toString();
    if (start != null && start.contains(':')) {
      final parts = start.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    if (end != null && end.contains(':')) {
      final parts = end.split(':');
      _endTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final langs = (widget.bio['languages'] as List?) ?? [];
    _languages = langs
        .map(
          (e) => {
            'language': (e as Map)['language']?.toString() ?? '',
            'proficiency': e['proficiency']?.toString() ?? '',
          },
        )
        .toList();
    final certs = (widget.bio['certifications'] as List?) ?? [];
    _certifications = certs
        .map(
          (e) => {
            'name': (e as Map)['name']?.toString() ?? '',
            'issuer': e['issuer']?.toString() ?? '',
          },
        )
        .toList();
  }

  @override
  void dispose() {
    _bioCtl.dispose();
    _yearsCtl.dispose();
    _otherSpecCtl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final url = await widget.onUploadAvatar(bytes, x.name);
    if (url != null) {
      setState(() {
        _avatarUrl = url;
      });
    }
  }

  void _addLanguage() {
    setState(() => _languages.add({'language': '', 'proficiency': ''}));
  }

  void _addCertification() {
    setState(() => _certifications.add({'name': '', 'issuer': ''}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF4ECDC4).withOpacity(0.2),
                    backgroundImage:
                        _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                        ? const Icon(
                            Icons.person,
                            color: Color(0xFF4ECDC4),
                            size: 32,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Upload photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHospitalDropdown(),
              const SizedBox(height: 12),
              _buildDropdown(
                label: 'Specialization',
                value: _specialization,
                items: widget.specializations,
                onChanged: (v) => setState(() => _specialization = v),
              ),
              if (_specialization == 'Other') ...[
                const SizedBox(height: 8),
                _buildText('Specify specialization', _otherSpecCtl),
              ],
              const SizedBox(height: 12),
              _buildMultiline('Bio', _bioCtl),
              const SizedBox(height: 12),
              _buildNumber('Years of Experience', _yearsCtl),
              const SizedBox(height: 16),
              Text(
                'Languages',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._languages.asMap().entries.map((e) => _langRow(e.key)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addLanguage,
                  icon: const Icon(Icons.add),
                  label: const Text('Add language'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Certifications',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._certifications.asMap().entries.map((e) => _certRow(e.key)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addCertification,
                  icon: const Icon(Icons.add),
                  label: const Text('Add certification'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Working Hours',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _dayPicker(),
              const SizedBox(height: 8),
              _timePickers(context),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final spec =
                        _specialization == 'Other' &&
                            _otherSpecCtl.text.trim().isNotEmpty
                        ? _otherSpecCtl.text.trim()
                        : _specialization;
                    final values = {
                      'avatar_url': _avatarUrl,
                      'hospital_id': _hospitalId,
                      'specialization': spec,
                      'bio': _bioCtl.text.trim().isEmpty
                          ? null
                          : _bioCtl.text.trim(),
                      'years_experience': int.tryParse(_yearsCtl.text.trim()),
                      'languages': _languages
                          .where(
                            (e) => (e['language']?.trim().isNotEmpty ?? false),
                          )
                          .toList(),
                      'certifications': _certifications
                          .where((e) => (e['name']?.trim().isNotEmpty ?? false))
                          .toList(),
                      'working_hours': _buildWorkingHoursPayload(),
                    };
                    await widget.onSaved(values);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langRow(int index) {
    final langCtl = TextEditingController(text: _languages[index]['language']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildOutlined(
              langCtl,
              hint: 'Language',
              onChanged: (v) => _languages[index]['language'] = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _proficiencyDropdown(index)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _languages.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _certRow(int index) {
    final nameCtl = TextEditingController(text: _certifications[index]['name']);
    final issuerCtl = TextEditingController(
      text: _certifications[index]['issuer'],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildOutlined(
              nameCtl,
              hint: 'Name',
              onChanged: (v) => _certifications[index]['name'] = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildOutlined(
              issuerCtl,
              hint: 'Issuer',
              onChanged: (v) => _certifications[index]['issuer'] = v,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _certifications.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildText(String label, TextEditingController ctl) {
    return TextFormField(
      controller: ctl,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNumber(String label, TextEditingController ctl) {
    return TextFormField(
      controller: ctl,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMultiline(String label, TextEditingController ctl) {
    return TextFormField(
      controller: ctl,
      maxLines: 4,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildOutlined(
    TextEditingController ctl, {
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: ctl,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      onChanged: (v) => setState(() => onChanged(v)),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Hospitals dropdown
  Widget _buildHospitalDropdown() {
    return DropdownButtonFormField<String>(
      value: _hospitalId,
      isExpanded: true,
      items: widget.hospitals
          .map(
            (h) => DropdownMenuItem<String>(
              value: h['id'] as String,
              child: Text(h['name'] as String),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _hospitalId = v),
      decoration: InputDecoration(
        labelText: 'Hospital',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Proficiency dropdown
  Widget _proficiencyDropdown(int index) {
    const options = ['beginner', 'fluent', 'native'];
    final current = _languages[index]['proficiency'] ?? '';
    return DropdownButtonFormField<String>(
      value: current.isNotEmpty ? current : null,
      isExpanded: true,
      items: options
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) =>
          setState(() => _languages[index]['proficiency'] = v ?? ''),
      decoration: const InputDecoration(
        hintText: 'Proficiency',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  // Day picker chips
  Widget _dayPicker() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 6,
      children: [
        for (final d in days)
          FilterChip(
            label: Text(d),
            selected: _selectedDays.contains(d),
            onSelected: (sel) => setState(() {
              if (sel) {
                _selectedDays.add(d);
              } else {
                _selectedDays.remove(d);
              }
            }),
          ),
      ],
    );
  }

  // Time pickers for start/end
  Widget _timePickers(BuildContext context) {
    String fmt(TimeOfDay? t) => t == null ? '--:--' : t.format(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
              );
              if (t != null) setState(() => _startTime = t);
            },
            icon: const Icon(Icons.play_arrow),
            label: Text('Start: ${fmt(_startTime)}'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
              );
              if (t != null) setState(() => _endTime = t);
            },
            icon: const Icon(Icons.stop),
            label: Text('End: ${fmt(_endTime)}'),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _buildWorkingHoursPayload() {
    String to24(TimeOfDay? t) {
      if (t == null) return '';
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return {
      'days': _selectedDays.toList(),
      'start': to24(_startTime),
      'end': to24(_endTime),
    };
  }
}

// Helpers to build profile card and info section from bio map
Widget _buildProfileCard(Map<String, dynamic> bio) {
  final name =
      Supabase.instance.client.auth.currentUser?.userMetadata?['full_name']
          ?.toString() ??
      'Doctor';
  final spec = bio['specialization']?.toString() ?? '—';
  final avatar = bio['avatar_url']?.toString();
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF4ECDC4).withOpacity(0.1), Colors.white],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFF4ECDC4).withOpacity(0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF4ECDC4), Color(0xFF44B3A3)],
            ),
          ),
          child: CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            backgroundImage: (avatar != null && avatar.isNotEmpty)
                ? NetworkImage(avatar)
                : null,
            child: (avatar == null || avatar.isEmpty)
                ? const Icon(Icons.person, color: Color(0xFF4ECDC4), size: 32)
                : null,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  spec,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF4ECDC4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoSection(
  Map<String, dynamic> bio, {
  required List<Map<String, dynamic>> hospitals,
}) {
  final hospId = bio['hospital_id']?.toString();
  String hospital = '—';
  if (hospId != null) {
    final found = hospitals.firstWhere(
      (h) => h['id'] == hospId,
      orElse: () => {},
    );
    hospital = (found['name']?.toString() ?? '—');
  }
  final wh = bio['working_hours'] as Map<String, dynamic>?;
  final working = _formatWorkingHours(wh);
  final years = bio['years_experience']?.toString();
  final langs =
      (bio['languages'] as List?)
          ?.map((e) => (e as Map)['language'])
          .whereType<String>()
          .toList() ??
      [];
  final certs =
      (bio['certifications'] as List?)
          ?.map((e) => (e as Map)['name'])
          .whereType<String>()
          .toList() ??
      [];

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
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
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF4ECDC4),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Basic Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoItem(Icons.location_on_outlined, 'Hospital', hospital),
        const SizedBox(height: 16),
        _buildInfoItem(Icons.access_time, 'Working Hours', working),
        const SizedBox(height: 16),
        _buildInfoItem(
          Icons.timeline,
          'Experience',
          years != null ? '$years years' : '—',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          Icons.language,
          'Languages',
          langs.isEmpty ? '—' : langs.join(', '),
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          Icons.workspace_premium_outlined,
          'Certifications',
          certs.isEmpty ? '—' : certs.join(', '),
        ),
        const SizedBox(height: 16),
        if ((bio['bio']?.toString().isNotEmpty ?? false))
          _buildInfoItem(
            Icons.description_outlined,
            'Bio',
            bio['bio'].toString(),
          ),
      ],
    ),
  );
}

String _formatWorkingHours(Map<String, dynamic>? wh) {
  if (wh == null) return '—';
  final days = (wh['days'] as List?)?.whereType<String>().toList() ?? [];
  final start = wh['start']?.toString() ?? '';
  final end = wh['end']?.toString() ?? '';
  final time = (start.isNotEmpty && end.isNotEmpty)
      ? '$start - $end'
      : (start + end);
  if (days.isEmpty && time.isEmpty) return '—';
  if (days.isNotEmpty && time.isNotEmpty) return '$time, ${days.join(', ')}';
  return days.isNotEmpty ? days.join(', ') : time;
}

Widget _buildInfoItem(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4ECDC4).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF4ECDC4)),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
