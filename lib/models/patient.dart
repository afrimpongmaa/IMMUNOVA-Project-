import 'package:flutter/material.dart';

class Patient {
  final int? localId;
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
  final String status;
  final Color statusColor;
  final Color avatarColor;

  Patient({
    this.localId,
    this.remoteId,
    required this.patientId,
    required this.docId,
    required this.name,
    required this.dob,
    required this.gender,
    this.emergencyContact,
    this.guardianName,
    this.guardianNum,
    this.lastTimeImmunized,
    this.status = 'Pending',
    this.statusColor = const Color(0xFFFFA726), // Default orange for pending
    this.avatarColor = const Color(0xFF4ECDC4), // Default teal
  });

  String get age {
    final now = DateTime.now();
    final difference = now.difference(dob);
    final years = (difference.inDays / 365).floor();
    return '$years years';
  }

  String get lastImmunized {
    if (lastTimeImmunized == null) return 'Not yet immunized';
    return '${lastTimeImmunized!.day}/${lastTimeImmunized!.month}/${lastTimeImmunized!.year}';
  }

  // Update toMap to include new fields
  Map<String, dynamic> toMap() => {
        if (localId != null) 'local_id': localId,
        'remote_id': remoteId,
        'patient_id': patientId,
        'doc_id': docId,
        'name': name,
        'dob': dob.toIso8601String(),
        'gender': gender,
        'emergency_contact': emergencyContact,
        'guardian_name': guardianName,
        'guardian_num': guardianNum,
        'last_time_immunized': lastTimeImmunized?.toIso8601String(),
        'status': status,
        'status_color': statusColor.value,
        'avatar_color': avatarColor.value,
      };

  factory Patient.fromMap(Map<String, dynamic> map) => Patient(
        localId: map['local_id'] as int?,
        remoteId: map['remote_id'] as String?,
        patientId: map['patient_id'] as String? ?? '',
        docId: (map['doc_id'] is int)
            ? map['doc_id'] as int
            : int.tryParse('${map['doc_id']}') ?? 0,
        name: map['name'] as String? ?? '',
        dob: DateTime.parse(map['dob'] as String),
        gender: map['gender'] as String? ?? 'M',
        emergencyContact: map['emergency_contact'] as String?,
        guardianName: map['guardian_name'] as String?,
        guardianNum: map['guardian_num'] as String?,
        lastTimeImmunized: map['last_time_immunized'] != null
            ? DateTime.parse(map['last_time_immunized'] as String)
            : null,
        status: map['status'] as String? ?? 'Pending',
        statusColor: Color((map['status_color'] ?? 0xFFFFA726) as int),
        avatarColor: Color((map['avatar_color'] ?? 0xFF4ECDC4) as int),
      );
}
