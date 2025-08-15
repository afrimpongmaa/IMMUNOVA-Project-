class Patient {
  final int localId;
  final String? remoteId;
  final String patientId;
  final int docId;
  final String name;
  final DateTime dob;
  final String gender;
  final String? emergencyContact;
  final String? guardianName;
  final String? guardianNum;
  final DateTime? lastTimeImmunized;
  final DateTime lastModified;
  final String syncStatus;

  Patient.fromMap(Map<String, dynamic> map)
      : localId = map['local_id'],
        remoteId = map['remote_id'],
        patientId = map['patient_id'],
        docId = map['doc_id'],
        name = map['name'],
        dob = DateTime.parse(map['dob']),
        gender = map['gender'],
        emergencyContact = map['emergency_contact_number'],
        guardianName = map['guardian_name'],
        guardianNum = map['guardian_num'],
        lastTimeImmunized = map['last_time_immunized'] != null 
            ? DateTime.parse(map['last_time_immunized'])
            : null,
        lastModified = DateTime.parse(map['last_modified']),
        syncStatus = map['sync_status'];

  Map<String, dynamic> toMap() => {
        'local_id': localId,
        'remote_id': remoteId,
        'patient_id': patientId,
        'doc_id': docId,
        'name': name,
        'dob': dob.toIso8601String(),
        'gender': gender,
        'emergency_contact_number': emergencyContact,
        'guardian_name': guardianName,
        'guardian_num': guardianNum,
        'last_time_immunized': lastTimeImmunized?.toIso8601String(),
        'last_modified': lastModified.toIso8601String(),
        'sync_status': syncStatus,
      };
}
