import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DebugUsersScreen extends StatefulWidget {
  const DebugUsersScreen({Key? key}) : super(key: key);

  @override
  State<DebugUsersScreen> createState() => _DebugUsersScreenState();
}

class _DebugUsersScreenState extends State<DebugUsersScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> immunizations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final allUsers = await _db.getAll('users');
      final allPatients = await _db.getAll('patients');
      final allImmunizations = await _db.getAll('immunizations');
      setState(() {
        users = allUsers;
        patients = allPatients;
        immunizations = allImmunizations;
        loading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debug: Database Contents'),
          backgroundColor: const Color(0xFF4ECDC4),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Patients'),
              Tab(text: 'Immunizations'),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildUsersList(),
                  _buildPatientsList(),
                  _buildImmunizationsList(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _loadData,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return users.isEmpty
        ? const Center(child: Text('No users found'))
        : ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${user['full_name']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Employee ID: ${user['employee_id']}'),
                      Text('Password: ${user['password']}'),
                      Text('Phone: ${user['phone_number']}'),
                      Text('Hospital: ${user['hospital_name']}'),
                      Text('Local ID: ${user['local_id']}'),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildPatientsList() {
    return patients.isEmpty
        ? const Center(child: Text('No patients found'))
        : ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${patient['name']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient ID: ${patient['patient_id']}'),
                      Text('Doc ID: ${patient['doc_id']}'),
                      Text('DOB: ${patient['dob']}'),
                      Text('Gender: ${patient['gender']}'),
                      Text('Local ID: ${patient['local_id']}'),
                      Text('Guardian: ${patient['guardian_name'] ?? 'None'}'),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildImmunizationsList() {
    return immunizations.isEmpty
        ? const Center(child: Text('No immunizations found'))
        : ListView.builder(
            itemCount: immunizations.length,
            itemBuilder: (context, index) {
              final immunization = immunizations[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Immunization ${immunization['local_id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient ID: ${immunization['patient_id']}'),
                      Text('Vaccine ID: ${immunization['vaccine_id']}'),
                      Text('Date: ${immunization['date_taken']}'),
                      Text('Dose: ${immunization['dose']}'),
                      Text('Status: ${immunization['status']}'),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
