import '../models/patient.dart';
import '../database/database_helper.dart';

class PatientRepository {
  final DatabaseHelper _db;
  static const String storeName = 'patients';

  PatientRepository(this._db);

  Future<int> addPatient(Patient patient) async {
    return await _db.insert(storeName, patient.toMap());
  }

  Future<List<Patient>> getAllPatients() async {
    final records = await _db.getAll(storeName);
    return records.map((record) => Patient.fromMap(record)).toList();
  }

  Future<List<Patient>> getPatientsByDoctor(int docId) async {
    final db = await _db.database;
    final txn = db.transaction(storeName, 'readonly');
    final store = txn.objectStore(storeName);
    final index = store.index('doc_id');

    final List<Patient> patients = [];
    await for (final cursor in index.openCursor(key: docId)) {
      patients.add(Patient.fromMap(cursor.value as Map<String, dynamic>));
    }

    await txn.completed;
    return patients;
  }
}
