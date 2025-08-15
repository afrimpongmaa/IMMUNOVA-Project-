class Immunization {
  final int? localId;
  final String? remoteId;
  final int patientId;
  final int vaccineId;
  final DateTime dateTaken;
  final String dose;
  final String status;

  Immunization({
    this.localId,
    this.remoteId,
    required this.patientId,
    required this.vaccineId,
    required this.dateTaken,
    required this.dose,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        if (localId != null) 'local_id': localId,
        'remote_id': remoteId,
        'patient_id': patientId,
        'vaccine_id': vaccineId,
        'date_due_taken': dateTaken.toIso8601String(),
        'dose': dose,
        'immunization_status': status,
      };

  factory Immunization.fromMap(Map<String, dynamic> map) => Immunization(
        localId: map['local_id'] as int?,
        remoteId: map['remote_id'] as String?,
        patientId: (map['patient_id'] is int)
            ? map['patient_id'] as int
            : int.tryParse('${map['patient_id']}') ?? 0,
        vaccineId: (map['vaccine_id'] is int)
            ? map['vaccine_id'] as int
            : int.tryParse('${map['vaccine_id']}') ?? 0,
        dateTaken: DateTime.parse(map['date_due_taken'] as String),
        dose: map['dose'] as String? ?? '',
        status: map['immunization_status'] as String? ?? 'Pending',
      );
}
