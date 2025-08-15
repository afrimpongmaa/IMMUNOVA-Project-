import '../database_helper.dart';
import '../models/patient.dart';

class PatientRepository {
  final dbHelper = DatabaseHelper();

  Future<List<Patient>> getAllPatients() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('patient_records');
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  Future<Patient?> getPatient(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'patient_records',
      where: 'local_id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<int> insertPatient(Patient patient) async {
    final db = await dbHelper.database;
    return await db.insert('patient_records', patient.toMap());
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await dbHelper.database;
    return await db.update(
      'patient_records',
      patient.toMap(),
      where: 'local_id = ?',
      whereArgs: [patient.localId],
    );
  }
}
