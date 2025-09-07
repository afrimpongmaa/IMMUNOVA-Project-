import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_helper.dart';

/// SyncService manages offline queueing and background sync when network returns.
class SyncService with ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _db = DatabaseHelper.instance;
  final _client = Supabase.instance.client;
  final _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  OverlayEntry? _bannerEntry;

  void start(BuildContext context) {
    // Initial state + watcher with safe fallbacks if plugin isn't available (e.g., web)
    () async {
      try {
        final res = await _connectivity.checkConnectivity();
        _updateOnline(context, _mapOnlineList(res));
        _sub ??= _connectivity.onConnectivityChanged.listen((results) async {
          final online = _mapOnlineList(results);
          _updateOnline(context, online);
          if (online) {
            try {
              await pushPending();
              await pullLatest();
              _showSnack(context, 'Synced successfully');
            } catch (e) {
              _showSnack(context, 'Sync failed, will retry');
            }
          }
        });
      } catch (e) {
        // On platforms where the plugin isn't registered (e.g., some web setups),
        // assume online to avoid crashing. Users will still be able to save; queued
        // sync will push next time the app detects connectivity after reload.
        debugPrint('[SyncService] Connectivity plugin unavailable: $e');
        _updateOnline(context, true);
      }
    }();
  }

  void disposeWatcher() {
    _sub?.cancel();
    _sub = null;
  }

  bool _mapOnlineList(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi);
  }

  void _updateOnline(BuildContext context, bool online) {
    if (_isOnline == online) return;
    _isOnline = online;
    notifyListeners();
    if (!online) {
      _showOfflineBanner(context);
    } else {
      _hideOfflineBanner();
    }
  }

  void _showOfflineBanner(BuildContext context) {
    _hideOfflineBanner();
  final overlay = Overlay.of(context);
    _bannerEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are offline. Changes will be saved locally and synced when back online.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(_bannerEntry!);
  }

  void _hideOfflineBanner() {
    _bannerEntry?.remove();
    _bannerEntry = null;
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> enqueue(String scope, String op, Map<String, dynamic> payload) async {
    await _db.enqueueOp(scope: scope, op: op, payload: payload);
  }

  /// Push pending mutations to the server via a Supabase Edge Function.
  /// Expects an Edge Function 'sync-push' that accepts a list of ops.
  Future<void> pushPending() async {
    final ops = await _db.getPendingOps(limit: 100);
    if (ops.isEmpty) return;
    // Transform to a compact JSON array
    final payload = ops
        .map((e) => {
              'id': e['id'],
              'scope': e['scope'],
              'op': e['op'],
              'payload': e['payload'],
              'created_at': e['created_at'],
            })
        .toList();

    final res = await _client.functions.invoke(
      'sync-push',
      body: jsonEncode({'ops': payload}),
    );
    if (res.status >= 200 && res.status < 300) {
      // Assume successful push; delete all acknowledged ops
      for (final row in ops) {
        await _db.deleteOp(row['id'] as int);
      }
    } else {
      // Leave in queue for retry
      for (final row in ops) {
        await _db.incrementRetry(row['id'] as int);
      }
      throw Exception('sync-push failed: ${res.status}');
    }
  }

  /// Pull latest data snapshot from server (optional). Expects 'sync-pull' Edge Function.
  Future<void> pullLatest() async {
    try {
      await _client.functions.invoke('sync-pull');
    } catch (_) {
      // Non-fatal; UI can continue.
    }
  }
}
