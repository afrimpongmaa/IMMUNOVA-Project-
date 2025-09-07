import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immunova/Screens/add_patient_page.dart';
import 'package:immunova/Screens/admin_page.dart';
import 'package:immunova/Screens/educational_resources.dart';
import 'package:immunova/Screens/patient_records.dart';
import 'package:immunova/Screens/profile.dart';
import 'package:immunova/Screens/reminders_page.dart';
import 'package:immunova/Screens/setting_page.dart';
import 'package:immunova/repositories/user_bio_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class MedicalHomeScreen extends StatefulWidget {
  const MedicalHomeScreen({super.key});
  @override
  State<MedicalHomeScreen> createState() => _MedicalHomeScreenState();
}

class _MedicalHomeScreenState extends State<MedicalHomeScreen> {
  String? _firstName;
  String? _avatarUrl; // from user_bio
  Map<String, dynamic>? _bio; // user_bio row

  // Chart state
  bool _loadingChart = true;
  int _countPending = 0;
  int _countOverdue = 0;
  int _countImmunized = 0;
  int? _activeSlice; // 0: pending, 1: overdue, 2: immunized

  final _bioRepo = UserBioRepository();

  @override
  void initState() {
    super.initState();
    _loadFirstName();
    _loadBio();
    _loadChartData();
  }

  Future<void> _loadFirstName() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final data = await Supabase.instance.client
          .from('users')
          .select('full_name')
          .eq('id', uid)
          .single();
      final fullName = (data['full_name'] as String?)?.trim() ?? '';
      final first = fullName.isEmpty
          ? null
          : fullName.split(RegExp(r'\s+')).first;
      if (mounted) setState(() => _firstName = first);
    } catch (_) {
      // ignore and keep fallback
    }
  }

  Future<void> _loadBio() async {
    try {
      final bio = await _bioRepo.getMyBio();
      if (!mounted) return;
      setState(() {
        _bio = bio;
        _avatarUrl = bio?['avatar_url'] as String?;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _runOverdueEdge() async {
    try {
      await Supabase.instance.client.functions.invoke(
        'mark-overdue',
        method: HttpMethod.post,
      );
    } catch (_) {
      // Local fallback
      try {
        final d = DateTime.now();
        final today = DateTime(
          d.year,
          d.month,
          d.day,
        ).toIso8601String().split('T').first;
        await Supabase.instance.client
            .from('immunization_records')
            .update({'status': 'overdue'})
            .lt('date_due', today)
            .eq('status', 'pending');
      } catch (_) {}
    }
  }

  Future<void> _loadChartData() async {
    setState(() => _loadingChart = true);
    try {
      final supa = Supabase.instance.client;
      final uid = supa.auth.currentUser?.id;
      if (uid == null) {
        setState(() {
          _countPending = 0;
          _countOverdue = 0;
          _countImmunized = 0;
          _loadingChart = false;
        });
        return;
      }

      // Ensure overdue is current
      await _runOverdueEdge();

      // Get this doctor's patient IDs
      final pRows = await supa
          .from('patient_records')
          .select('patient_id')
          .eq('doc_id', uid);
      final ids = (pRows as List)
          .map((e) => e['patient_id'] as String)
          .toList();
      if (ids.isEmpty) {
        setState(() {
          _countPending = 0;
          _countOverdue = 0;
          _countImmunized = 0;
          _loadingChart = false;
        });
        return;
      }

      // Fetch statuses for those patients
      final rows = await supa
          .from('immunization_records')
          .select('status, patient_id')
          .inFilter('patient_id', ids);

      int pending = 0, overdue = 0, immunized = 0;
      for (final r in (rows as List)) {
        final s = (r['status'] as String?)?.toLowerCase() ?? '';
        if (s == 'pending')
          pending++;
        else if (s == 'overdue')
          overdue++;
        else if (s == 'immunized')
          immunized++;
      }

      if (!mounted) return;
      setState(() {
        _countPending = pending;
        _countOverdue = overdue;
        _countImmunized = immunized;
        _loadingChart = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingChart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorProfileScreen(),
                  ),
                ).then((_) {
                  // Refresh bio/avatar when returning
                  _loadBio();
                }),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44B3A3)],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFF4ECDC4),
                        size: 22,
                      )
                    : null,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'IMMU NOVA',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D3748),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RemindersPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            InkWell(
              onTap: _openBioModal,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4ECDC4).withOpacity(0.12),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withOpacity(0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.handshake,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'WELCOME, Dr ${_firstName ?? 'Clinician'}!',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Quick Access',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _QuickCard(
                  icon: Icons.folder_open,
                  title: 'Patient Records',
                  subtitle: 'Manage Patient Information',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF80DEEA), Color(0xFF4DD0E1)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientRecords(),
                    ),
                  ),
                ),
                _QuickCard(
                  icon: Icons.school,
                  title: 'Educational Resources',
                  subtitle: 'Access Learning Materials',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB39DDB), Color(0xFF9575CD)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EducationalResourcesPage(),
                    ),
                  ),
                ),
                _QuickCard(
                  icon: Icons.person_add,
                  title: 'Add Patient',
                  subtitle: 'Create New Patient Record',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA5D6A7), Color(0xFF81C784)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPatientScreen(),
                    ),
                  ),
                ),
                _QuickCard(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'Preferences & Config',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // NEW: Immunization Pie Chart section (before Recent Activity)
            _buildImmunizationOverview(),

            const SizedBox(height: 24),

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF4ECDC4),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4ECDC4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _ActivityItem(
              title: 'New Patient Record Created: Alex Wood',
              time: '2 hours ago',
              statusText: 'Follow Up',
              statusColor: Colors.pink,
            ),
            const SizedBox(height: 12),
            _ActivityItem(
              title: 'Updated Immunization for Child: Sarah Pitt',
              time: '5 hours ago',
              statusText: 'Completed',
              statusColor: Colors.blue,
            ),
            const SizedBox(height: 12),
            _ActivityItem(
              title: 'New Immunization Records: Noah Asante',
              time: '1 day ago',
              statusText: 'Review',
              statusColor: Colors.orange,
            ),
            const SizedBox(height: 20),

            // Keep your existing ImmunizationOverviewWidget if present
            // ...existing code...
          ],
        ),
      ),
    );
  }

  void _openBioModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bio = _bio;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: bio == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Oops, no bio data to show',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add your professional details to personalize your profile.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DoctorProfileScreen(),
                            ),
                          ).then((_) => _loadBio());
                        },
                        icon: const Icon(Icons.edit),
                        label: Text(
                          'Add Bio',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF4ECDC4),
                                    Color(0xFF44B3A3),
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    (_avatarUrl != null &&
                                        _avatarUrl!.isNotEmpty)
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child:
                                    (_avatarUrl == null || _avatarUrl!.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        color: Color(0xFF4ECDC4),
                                        size: 36,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Dr ${_firstName ?? 'Clinician'}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _bioItem(
                        Icons.badge_outlined,
                        'Specialization',
                        (bio['specialization'] ?? '—').toString(),
                      ),
                      const SizedBox(height: 10),
                      _bioItem(
                        Icons.timeline,
                        'Experience',
                        bio['years_experience'] != null
                            ? '${bio['years_experience']} years'
                            : '—',
                      ),
                      const SizedBox(height: 10),
                      _bioItem(
                        Icons.access_time,
                        'Working Hours',
                        _formatWorking(
                          bio['working_hours'] as Map<String, dynamic>?,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _bioItem(
                        Icons.language,
                        'Languages',
                        _joinListOfMaps(bio['languages'], 'language'),
                      ),
                      const SizedBox(height: 10),
                      _bioItem(
                        Icons.workspace_premium_outlined,
                        'Certifications',
                        _joinListOfMaps(bio['certifications'], 'name'),
                      ),
                      if ((bio['bio']?.toString().isNotEmpty ?? false)) ...[
                        const SizedBox(height: 10),
                        _bioItem(
                          Icons.description_outlined,
                          'Bio',
                          bio['bio'].toString(),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _bioItem(IconData icon, String label, String value) {
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : '—',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatWorking(Map<String, dynamic>? wh) {
    if (wh == null) return '—';
    final days =
        (wh['days'] as List?)?.whereType<String>().toList() ?? const [];
    final start = wh['start']?.toString() ?? '';
    final end = wh['end']?.toString() ?? '';
    final time = (start.isNotEmpty && end.isNotEmpty)
        ? '$start - $end'
        : (start + end);
    if (days.isEmpty && time.isEmpty) return '—';
    if (days.isNotEmpty && time.isNotEmpty) return '$time, ${days.join(', ')}';
    return days.isNotEmpty ? days.join(', ') : time;
  }

  String _joinListOfMaps(dynamic value, String key) {
    final list = (value as List?) ?? const [];
    final items = list
        .map((e) => (e is Map ? (e[key]?.toString() ?? '') : ''))
        .where((s) => s.isNotEmpty)
        .toList();
    return items.isEmpty ? '—' : items.join(', ');
  }

  Widget _buildImmunizationOverview() {
    final total = _countPending + _countOverdue + _countImmunized;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
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
                  Icons.pie_chart,
                  color: Color(0xFF4ECDC4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Immunization Overview',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                onPressed: _loadChartData,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingChart)
            const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (total == 0)
            Container(
              height: 160,
              alignment: Alignment.center,
              child: Text(
                'No data yet',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final data = [
                  (_countPending, const Color(0xFFFFC107)), // amber
                  (_countOverdue, const Color(0xFFE53935)), // red
                  (_countImmunized, const Color(0xFF43A047)), // green
                ];
                final labels = ['Pending', 'Overdue', 'Immunized'];
                return Column(
                  children: [
                    GestureDetector(
                      onTapDown: (details) {
                        final box = context.findRenderObject() as RenderBox;
                        final offset = box.globalToLocal(
                          details.globalPosition,
                        );
                        final center = Offset(c.maxWidth / 2, 100);
                        final v = offset - center;
                        final angle =
                            (math.atan2(v.dy, v.dx) + 2 * math.pi) %
                            (2 * math.pi);
                        final sum = data.fold<int>(0, (a, b) => a + b.$1);
                        double acc = 0;
                        int? hit;
                        for (int i = 0; i < data.length; i++) {
                          final sweep = (data[i].$1 / sum) * 2 * math.pi;
                          if (angle >= acc && angle < acc + sweep) {
                            hit = i;
                            break;
                          }
                          acc += sweep;
                        }
                        setState(() => _activeSlice = hit);
                      },
                      child: SizedBox(
                        height: 240,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (_, t, __) => CustomPaint(
                            painter: _PiePainter(
                              values: data.map((e) => e.$1.toDouble()).toList(),
                              colors: data.map((e) => e.$2).toList(),
                              progress: t,
                              highlightIndex: _activeSlice,
                            ),
                            child: Center(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _activeSlice == null
                                          ? '$total'
                                          : '${data[_activeSlice!].$1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: _activeSlice == null
                                            ? const Color(0xFF2D3748)
                                            : data[_activeSlice!].$2,
                                      ),
                                    ),
                                    Text(
                                      _activeSlice == null
                                          ? 'Total'
                                          : labels[_activeSlice!],
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: List.generate(3, (i) {
                        final isActive = _activeSlice == i;
                        final icons = [
                          Icons.pending_actions,
                          Icons.warning,
                          Icons.check_circle,
                        ];
                        return GestureDetector(
                          onTap: () => setState(
                            () => _activeSlice = _activeSlice == i ? null : i,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? data[i].$2.withOpacity(0.1)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? data[i].$2
                                    : Colors.grey[200]!,
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icons[i], size: 16, color: data[i].$2),
                                const SizedBox(width: 6),
                                Text(
                                  '${labels[i]}: ${data[i].$1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isActive
                                        ? data[i].$2
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// Simple animated pie painter with optional highlighted slice
class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.values,
    required this.colors,
    required this.progress,
    this.highlightIndex,
  });

  final List<double> values;
  final List<Color> colors;
  final double progress; // 0..1
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    final radius = math.min(size.width, size.height) / 2.6;
    final center = Offset(size.width / 2, size.height / 2);
    var start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi * progress;
      final isHighlighted = i == highlightIndex;

      paint.strokeWidth = isHighlighted ? radius * 0.85 : radius * 0.75;
      paint.color = colors[i].withOpacity(isHighlighted ? 1.0 : 0.9);

      final adjustedRadius = isHighlighted ? radius * 1.05 : radius;
      final rect = Rect.fromCircle(center: center, radius: adjustedRadius);

      // Add subtle shadow for highlighted slice
      if (isHighlighted) {
        final shadowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = paint.strokeWidth
          ..color = colors[i].withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawArc(rect, start, sweep, false, shadowPaint);
      }

      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.values != values ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.black87, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final String statusText;
  final Color statusColor;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            radius: 20,
            child: const Icon(Icons.person, color: Colors.black54, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
