import 'package:flutter/material.dart';
import 'package:immunova/Screens/add_patient_page.dart';
import 'package:immunova/Screens/educational_resources.dart';
import 'package:immunova/Screens/setting_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // added
import 'package:immunova/widgets/success_modal.dart'; // added

class PatientRecords extends StatefulWidget {
  const PatientRecords({super.key});

  @override
  State<PatientRecords> createState() => _PatientRecordsState();
}

class _PatientRecordsState extends State<PatientRecords> {
  String selectedFilter = 'All';
  int selectedBottomNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final List<String> filters = ['All', 'Pending', 'Immunized', 'Overdue'];

  List<PatientRecord> patients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  // Call Edge Function to flip pending -> overdue (doctor-scoped or single patient)
  Future<void> _runOverdueEdge({String? patientId}) async {
    try {
      final fn = Supabase.instance.client.functions;
      await fn.invoke(
        'mark-overdue',
        method: HttpMethod.post,
        body: patientId != null ? {'patient_id': patientId} : {},
      );
    } catch (_) {
      // Fallback local update if Edge Function is unreachable
      try {
        final d = DateTime.now();
        final today = DateTime(
          d.year,
          d.month,
          d.day,
        ).toIso8601String().split('T').first;
        var q = Supabase.instance.client
            .from('immunization_records')
            .update({'status': 'overdue'})
            .lt('date_due', today)
            .eq('status', 'pending');
        if (patientId != null) q = q.eq('patient_id', patientId);
        await q;
      } catch (_) {
        // ignore
      }
    }
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        setState(() {
          patients = [];
          _loading = false;
        });
        return;
      }

      // Ensure statuses are current for this doctor before fetching
      await _runOverdueEdge();

      final res = await Supabase.instance.client
          .from('patient_records')
          .select(
            'patient_id, name, dob, updated_at, immunization_records(status, date_due, updated_at)',
          )
          .eq('doc_id', uid)
          .order('updated_at', ascending: false)
          .order(
            'updated_at',
            referencedTable: 'immunization_records',
            ascending: false,
          )
          .limit(1, referencedTable: 'immunization_records');

      final list = (res as List).map((e) {
        final name = (e['name'] as String?) ?? '-';
        final dobStr = (e['dob'] as String?) ?? '';
        final ageGroup = _ageGroupFromDob(dobStr);
        final ims = (e['immunization_records'] as List?) ?? [];
        String status = 'pending';
        String label = 'No immunizations';
        if (ims.isNotEmpty) {
          final i = ims.first as Map<String, dynamic>;
          status = (i['status'] as String?) ?? 'pending';
          final due = (i['date_due'] as String?) ?? '-';
          label = due == '-' ? 'No due date' : 'Due: $due';
        }
        return PatientRecord(
          patientId: e['patient_id'] as String,
          name: name.toUpperCase(),
          age: ageGroup,
          lastImmunized: label,
          status: status,
          statusColor: _statusColor(status),
          avatarColor: const Color(0xFF4ECDC4),
        );
      }).toList();

      setState(() {
        patients = list;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to load patients';
        _loading = false;
      });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'immunized':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.amber[700]!;
    }
  }

  String _ageGroupFromDob(String dobIso) {
    if (dobIso.isEmpty) return '(N/A)';
    try {
      final dob = DateTime.parse(dobIso);
      final now = DateTime.now();
      final years =
          now.year -
          dob.year -
          ((now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day))
              ? 1
              : 0);
      if (years < 1) return '(0-1 year)';
      if (years < 3) return '(1-3 years)';
      if (years < 6) return '(3-6 years)';
      if (years < 13) return '(6-12 years)';
      return '($years yrs)';
    } catch (_) {
      return '(N/A)';
    }
  }

  List<PatientRecord> get filteredPatients {
    List<PatientRecord> filtered = List.of(patients);
    switch (selectedFilter) {
      case 'Pending':
        filtered = filtered.where((p) => p.status == 'pending').toList();
        break;
      case 'Immunized':
        filtered = filtered.where((p) => p.status == 'immunized').toList();
        break;
      case 'Overdue':
        filtered = filtered.where((p) => p.status == 'overdue').toList();
        break;
    }
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (p) => p.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'PATIENT RECORDS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
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
                  Text(_error!),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _loadPatients,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search & Filter
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search patients by name or ID',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: filters
                            .map((f) => _buildFilterTab(f))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                // Patient List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPatients,
                    child: filteredPatients.isEmpty
                        ? const Center(child: Text('No patients found'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredPatients.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildPatientCard(filteredPatients[index]),
                            ),
                          ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFilterTab(String filter) {
    final isSelected = selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = filter),
        child: Container(
          margin: EdgeInsets.only(right: filter != filters.last ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            filter,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(PatientRecord patient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: patient.avatarColor,
                  radius: 25,
                  child: Text(
                    patient.name
                        .split(' ')
                        .map((n) => n.isNotEmpty ? n[0] : '')
                        .take(2)
                        .join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        patient.age,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editPatient(patient);
                        if (value == 'delete') _deletePatient(patient);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: patient.statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        // Capitalize for display
                        patient.status[0].toUpperCase() +
                            patient.status.substring(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  patient.lastImmunized,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPatientDetails(patient),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                    ),
                    onPressed: () => _openLogImmunizationSheet(patient),
                    child: const Text(
                      'Log Immunization',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
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
    final isActive = selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => selectedBottomNavIndex = index);
        _handleBottomNavTap(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? Color(0xFF4ECDC4) : Colors.grey,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              color: isActive ? Color(0xFF4ECDC4) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EducationalResourcesPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddPatientScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
        break;
    }
  }

  void _editPatient(PatientRecord patient) {
    final nameCtrl = TextEditingController(text: patient.name);
    final ageCtrl = TextEditingController(text: patient.age);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: ageCtrl,
              decoration: InputDecoration(labelText: 'Age Group'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                patient.name = nameCtrl.text;
                patient.age = ageCtrl.text;
                // Status and statusColor remain unchanged
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4ECDC4)),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deletePatient(PatientRecord patient) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Patient'),
        content: Text('Are you sure you want to delete this patient?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => patients.remove(patient));
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // NEW: multi-select sheet to log specific immunizations (pending or overdue)
  Future<void> _openLogImmunizationSheet(PatientRecord patient) async {
    // Ensure latest statuses
    await _runOverdueEdge(patientId: patient.patientId);

    final supa = Supabase.instance.client;
    final rows = await supa
        .from('immunization_records')
        .select('id, vaccines(vaccine_name), dose, date_due, status')
        .eq('patient_id', patient.patientId)
        .inFilter('status', ['pending', 'overdue'])
        .order('date_due', ascending: true);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending/overdue immunizations'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selected = <String>{};

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final allSelected = selected.length == list.length;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select immunizations to mark done',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: allSelected,
                        onChanged: (_) {
                          setSheet(() {
                            if (allSelected) {
                              selected.clear();
                            } else {
                              selected
                                ..clear()
                                ..addAll(list.map((e) => e['id'] as String));
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      const Text('Select all'),
                    ],
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final r = list[i];
                        final id = r['id'] as String;
                        final vac =
                            (r['vaccines']
                                    as Map<String, dynamic>?)?['vaccine_name']
                                as String? ??
                            'Vaccine';
                        final dose = (r['dose'] as String?) ?? '-';
                        final due = (r['date_due'] as String?) ?? '-';
                        final st = (r['status'] as String?) ?? 'pending';
                        final checked = selected.contains(id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (_) => setSheet(() {
                            if (checked) {
                              selected.remove(id);
                            } else {
                              selected.add(id);
                            }
                          }),
                          title: Text(
                            vac,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Dose: $dose • Due: $due • ${st[0].toUpperCase()}${st.substring(1)}',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () async {
                              final ids = selected.toList();
                              await Supabase.instance.client
                                  .from('immunization_records')
                                  .update({'status': 'immunized'})
                                  .inFilter('id', ids);
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              await _loadPatients();
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => SuccessModal(
                                  title: 'Immunized',
                                  message:
                                      'Selected immunizations marked as done.',
                                  onClose: () => Navigator.of(context).pop(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                      ),
                      child: const Text(
                        'Mark as done',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ENHANCED: include patient header info + immunization list
  Future<void> _showPatientDetails(PatientRecord patient) async {
    // Update overdue first
    await _runOverdueEdge(patientId: patient.patientId);

    final supa = Supabase.instance.client;

    // Fetch patient info
    final p = await supa
        .from('patient_records')
        .select('name, dob, gender, guardian_name, guardian_num')
        .eq('patient_id', patient.patientId)
        .single();

    final dobStr = (p['dob'] as String?) ?? '';
    final ageGroup = _ageGroupFromDob(dobStr);
    final gender = (p['gender'] as String?) ?? '';
    final gName = (p['guardian_name'] as String?) ?? '-';
    final gNum = (p['guardian_num'] as String?) ?? '-';

    // Fetch immunizations with vaccine names
    final rows = await supa
        .from('immunization_records')
        .select(
          'id, status, dose, date_due, updated_at, vaccines(vaccine_name)',
        )
        .eq('patient_id', patient.patientId)
        .order('date_due', ascending: true);

    final list = (rows as List).cast<Map<String, dynamic>>();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Header with avatar and patient info
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF4ECDC4),
                    child: Text(
                      (p['name'] as String? ?? patient.name)
                          .split(' ')
                          .map((n) => n.isNotEmpty ? n[0] : '')
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (p['name'] as String? ?? patient.name),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$ageGroup • ${gender.isEmpty ? 'N/A' : gender}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'DOB: ${dobStr.isEmpty ? '-' : dobStr}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.family_restroom,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Guardian: $gName • ${gNum == '-' ? 'N/A' : gNum}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Immunization Details',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No immunization records yet.'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = list[i];
                      final vac =
                          (r['vaccines']
                                  as Map<String, dynamic>?)?['vaccine_name']
                              as String? ??
                          'Vaccine';
                      final dose = (r['dose'] as String?) ?? '-';
                      final due = (r['date_due'] as String?) ?? '-';
                      final st = (r['status'] as String?) ?? 'pending';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(st).withOpacity(0.15),
                          child: Icon(Icons.vaccines, color: _statusColor(st)),
                        ),
                        title: Text(
                          vac,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Dose: $dose • Due: $due\nStatus: ${st[0].toUpperCase()}${st.substring(1)}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openLogImmunizationSheet(patient);
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Log Immunization(s)'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Old quick logger (kept as fallback, now marks pending+overdue)
  Future<void> _showImmunizationLog(PatientRecord patient) async {
    final supa = Supabase.instance.client;
    await supa
        .from('immunization_records')
        .update({'status': 'immunized'})
        .eq('patient_id', patient.patientId)
        .inFilter('status', [
          'pending',
          'overdue',
        ]); // CHANGED to include overdue
    await _loadPatients();
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessModal(
        title: 'Immunized',
        message: 'Immunization logged successfully.',
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class PatientRecord {
  final String patientId;
  String name;
  String age;
  String lastImmunized;
  String status;
  Color statusColor;
  final Color avatarColor;

  PatientRecord({
    required this.patientId,
    required this.name,
    required this.age,
    required this.lastImmunized,
    required this.status,
    required this.statusColor,
    required this.avatarColor,
  });
}
