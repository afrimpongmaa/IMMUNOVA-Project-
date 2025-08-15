import 'package:flutter/material.dart';
import 'package:immunova/Screens/add_patient_page.dart';
import 'package:immunova/Screens/educational_resources.dart';
import 'package:immunova/Screens/setting_page.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';
import '../providers/user_session.dart';

class PatientRecords extends StatefulWidget {
  const PatientRecords({super.key});

  @override
  State<PatientRecords> createState() => _PatientRecordsState();
}

class _PatientRecordsState extends State<PatientRecords> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  int selectedBottomNavIndex = 0; // Add this line

  final TextEditingController _searchController = TextEditingController();

  final List<String> filters = ['All Patients', 'immunized', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final session = Provider.of<UserSession>(context, listen: false);
      final userId = session.localId;
      List<Map<String, dynamic>> records;
      if (userId != null) {
        records = await _db.queryByIndex('patients', 'doc_id', userId);
      } else {
        records = await _db.getAll('patients'); // fallback if no user
      }
      setState(() {
        _patients = records.map((r) => Patient.fromMap(r)).toList();
        _filteredPatients = _patients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading patients: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterPatients(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients
            .where((patient) =>
                patient.status.toLowerCase() == filter.toLowerCase())
            .toList();
      }
    });
  }

  void _updatePatient(Patient oldPatient, String newName, String newAge) async {
    try {
      // Create new patient instance with updated values
      final updatedPatient = Patient(
        localId: oldPatient.localId,
        remoteId: oldPatient.remoteId,
        patientId: oldPatient.patientId,
        docId: oldPatient.docId,
        name: newName,
        dob: DateTime.now().subtract(
            Duration(days: 365 * int.parse(newAge))), // Convert age to DOB
        gender: oldPatient.gender,
        guardianName: oldPatient.guardianName,
        guardianNum: oldPatient.guardianNum,
        status: oldPatient.status,
        statusColor: oldPatient.statusColor,
        avatarColor: oldPatient.avatarColor,
      );

      // Update in database
      await _db.update('patients', updatedPatient.toMap(), oldPatient.localId!);

      // Update state
      setState(() {
        final index =
            _patients.indexWhere((p) => p.localId == oldPatient.localId);
        if (index != -1) {
          _patients[index] = updatedPatient;
        }
        _filterPatients(_selectedFilter);
      });
    } catch (e) {
      print('Error updating patient: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    final name = session.displayName ?? 'Doctor';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
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
      body: Column(
        children: [
          // Search & Filter
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search patients by name or ID',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children:
                      filters.map((filter) => _buildFilterTab(filter)).toList(),
                ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(20),
                    itemCount: _filteredPatients.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _buildPatientCard(_filteredPatients[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFilterTab(String filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: Container(
          margin: EdgeInsets.only(right: filter != filters.last ? 8 : 0),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF4ECDC4) : Colors.grey[200],
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

  Widget _buildPatientCard(Patient patient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: patient.avatarColor,
                  radius: 25,
                  child: Text(
                    patient.name.split(' ').map((n) => n[0]).take(2).join(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
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
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: patient.statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        patient.status,
                        style: TextStyle(
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
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  patient.lastImmunized,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPatientDetails(patient),
                    child: Text(
                      'View Details',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4ECDC4),
                    ),
                    onPressed: () => _showImmunizationLog(patient),
                    child: Text(
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

  void _editPatient(Patient patient) {
    _showEditDialog(patient);
  }

  void _showEditDialog(Patient patient) {
    final nameCtrl = TextEditingController(text: patient.name);
    final ageCtrl =
        TextEditingController(text: patient.age.replaceAll(' years', ''));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: ageCtrl,
              decoration: InputDecoration(labelText: 'Age (years)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Parse age safely as int
              final parsedAge = int.tryParse(ageCtrl.text) ?? 0;
              // Create a new Patient instance with updated values
              final updatedPatient = Patient(
                localId: patient.localId,
                remoteId: patient.remoteId,
                patientId: patient.patientId,
                docId: patient.docId,
                name: nameCtrl.text,
                dob: DateTime.now().subtract(Duration(days: 365 * parsedAge)),
                gender: patient.gender,
                emergencyContact: patient.emergencyContact,
                guardianName: patient.guardianName,
                guardianNum: patient.guardianNum,
                lastTimeImmunized: patient.lastTimeImmunized,
                status: patient.status,
                statusColor: patient.statusColor,
                avatarColor: patient.avatarColor,
              );
              // Update in database (assuming you have an update method)
              await _db.update(
                  'patients', updatedPatient.toMap(), patient.localId!);
              setState(() {
                final idx =
                    _patients.indexWhere((p) => p.localId == patient.localId);
                if (idx != -1) _patients[idx] = updatedPatient;
                _filterPatients(_selectedFilter);
              });
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deletePatient(Patient patient) {
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
              setState(() => _patients.remove(patient));
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(Patient patient) {
    // Your existing implementation
  }

  void _showImmunizationLog(Patient patient) {
    // Your existing implementation
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
