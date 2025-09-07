import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _client = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  bool _onlyUnread = false;
  bool _onlyCritical = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Trigger mark-overdue on open (authenticated scope)
      await _client.functions.invoke('mark-overdue', method: HttpMethod.post);

      final rows = await _client
          .from('notifications')
          .select('id, patient_id, severity, content, created_at, read_at')
          .order('created_at', ascending: false)
          .limit(100);
      final list = (rows as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load notifications';
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _client
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .isFilter('read_at', null);
      await _refresh();
    } catch (_) {}
  }

  Future<void> _markRead(String id) async {
    try {
      await _client
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      setState(() {
        final i = _items.indexWhere((e) => e['id'] == id);
        if (i != -1) _items[i]['read_at'] = DateTime.now().toIso8601String();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((n) {
      final unread = n['read_at'] == null;
      final critical = (n['severity'] as String?) == 'critical';
      if (_onlyUnread && !unread) return false;
      if (_onlyCritical && !critical) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _onlyUnread ? 'Show all' : 'Show unread',
            onPressed: () => setState(() => _onlyUnread = !_onlyUnread),
            icon: Icon(
              _onlyUnread ? Icons.mark_email_read : Icons.mark_email_unread,
              color: const Color(0xFF4ECDC4),
            ),
          ),
          IconButton(
            tooltip: _onlyCritical ? 'Show all severities' : 'Show critical only',
            onPressed: () => setState(() => _onlyCritical = !_onlyCritical),
            icon: Icon(
              Icons.warning_amber,
              color: _onlyCritical ? Colors.red : const Color(0xFF4ECDC4),
            ),
          ),
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all, color: Color(0xFF4ECDC4)),
          ),
          const SizedBox(width: 8),
        ],
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
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      TextButton(onPressed: _refresh, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Center(
                              child: Text('No notifications',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final n = filtered[index];
                            final critical = (n['severity'] as String?) == 'critical';
                            final unread = n['read_at'] == null;
                            final createdAt = n['created_at']?.toString();
                            final ts = _fmtWhen(createdAt);
                            return Dismissible(
                              key: ValueKey(n['id'] as String),
                              direction: unread ? DismissDirection.endToStart : DismissDirection.none,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                color: Colors.green,
                                child: const Icon(Icons.mark_email_read, color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                await _markRead(n['id'] as String);
                                return false; // Don't remove the tile
                              },
                              child: _NotificationTile(
                                content: (n['content'] as String?) ?? 'Notification',
                                patientId: n['patient_id']?.toString(),
                                timestamp: ts,
                                critical: critical,
                                unread: unread,
                                onMarkRead: unread ? () => _markRead(n['id'] as String) : null,
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  String _fmtWhen(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      return '$d/$m ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final String content;
  final String? patientId;
  final String timestamp;
  final bool critical;
  final bool unread;
  final VoidCallback? onMarkRead;

  const _NotificationTile({
    required this.content,
    required this.patientId,
    required this.timestamp,
    required this.critical,
    required this.unread,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = critical ? Colors.red : const Color(0xFF4ECDC4);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              critical ? Icons.warning_amber_rounded : Icons.notifications,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        content,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    Text(
                      timestamp,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                if (patientId != null && patientId!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Patient: $patientId',
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (unread) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onMarkRead,
                      icon: const Icon(Icons.mark_email_read, size: 18),
                      label: const Text('Mark as read'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

