import 'package:supabase_flutter/supabase_flutter.dart';

class UserBioRepository {
  final SupabaseClient _client;
  UserBioRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>?> getMyBio() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await _client
        .from('user_bio')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return res;
  }

  Future<List<Map<String, dynamic>>> getHospitals() async {
    final rows = await _client
        .from('hospitals')
        .select('id,name')
        .order('name');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> upsertMyBio(Map<String, dynamic> values) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final payload = {'user_id': uid, ...values};
    await _client.from('user_bio').upsert(payload);
  }

  Future<Map<String, int>> getMyStats() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {'patients_immunized': 0, 'total_patients': 0};

    // total patients under this doctor
    final patientRows = await _client
        .from('patient_records')
        .select('patient_id')
        .eq('doc_id', uid);
    final patientIds = (patientRows as List)
        .map((e) => e['patient_id'])
        .whereType<String>()
        .toList();
    final totalPatients = patientIds.length;

    // patients with at least one immunization (distinct patient_id)
    int patientsImmunized = 0;
    if (patientIds.isNotEmpty) {
      final immunRows = await _client
          .from('immunizations')
          .select('patient_id')
          .inFilter('patient_id', patientIds);
      final distinct = <String>{};
      for (final r in (immunRows as List)) {
        final id = r['patient_id'] as String?;
        if (id != null) distinct.add(id);
      }
      patientsImmunized = distinct.length;
    }

    return {
      'patients_immunized': patientsImmunized,
      'total_patients': totalPatients,
    };
  }
}
