import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Lightweight local DB for offline queueing and caching small datasets.
class DatabaseHelper {
	static final DatabaseHelper instance = DatabaseHelper._internal();
	DatabaseHelper._internal();

		Database? _db;
		static const _webKey = 'pending_ops_web';

		Future<Database> get database async {
			if (kIsWeb) {
				throw UnsupportedError('sqflite not available on web');
			}
			if (_db != null) return _db!;
			_db = await _initDB('immunova_local.db');
			return _db!;
		}

	Future<Database> _initDB(String fileName) async {
		final dbPath = await getDatabasesPath();
		final path = p.join(dbPath, fileName);
		return await openDatabase(
			path,
			version: 1,
			onCreate: (db, version) async {
				// Generic pending operations queue. Each row is a mutation envelope.
				await db.execute('''
					CREATE TABLE IF NOT EXISTS pending_ops (
						id INTEGER PRIMARY KEY AUTOINCREMENT,
						scope TEXT NOT NULL,              -- e.g., "user_bio", "patient", "immunization"
						op TEXT NOT NULL,                 -- e.g., "upsert", "insert", "update", "delete"
						payload TEXT NOT NULL,            -- JSON string with the data to push
						created_at INTEGER NOT NULL,      -- epoch millis
						retry_count INTEGER NOT NULL DEFAULT 0
					);
				''');
				// Optional small caches can be added here later (e.g., hospitals cache)
			},
		);
	}

	Future<int> enqueueOp({
		required String scope,
		required String op,
		required Map<String, dynamic> payload,
	}) async {
			if (kIsWeb) {
				final prefs = await SharedPreferences.getInstance();
				final now = DateTime.now().millisecondsSinceEpoch;
				final list = (prefs.getStringList(_webKey) ?? []);
				final id = list.length + 1; // simple local id
				final entry = jsonEncode({
					'id': id,
					'scope': scope,
					'op': op,
					'payload': payload,
					'created_at': now,
					'retry_count': 0,
				});
				list.add(entry);
				await prefs.setStringList(_webKey, list);
				return id;
			} else {
				final db = await database;
				return await db.insert('pending_ops', {
					'scope': scope,
					'op': op,
					'payload': jsonEncode(payload),
					'created_at': DateTime.now().millisecondsSinceEpoch,
					'retry_count': 0,
				});
			}
	}

	Future<List<Map<String, dynamic>>> getPendingOps({int limit = 50}) async {
			if (kIsWeb) {
				final prefs = await SharedPreferences.getInstance();
				final list = (prefs.getStringList(_webKey) ?? []);
				final decoded = list
						.map((s) => jsonDecode(s) as Map<String, dynamic>)
						.toList()
					..sort((a, b) => (a['created_at'] as int)
							.compareTo(b['created_at'] as int));
				return decoded.take(limit).toList();
			} else {
				final db = await database;
				final rows = await db.query(
					'pending_ops',
					orderBy: 'created_at ASC, id ASC',
					limit: limit,
				);
				return rows
						.map((r) => {
									...r,
									'payload': jsonDecode(r['payload'] as String),
								})
						.toList();
			}
	}

	Future<void> deleteOp(int id) async {
			if (kIsWeb) {
				final prefs = await SharedPreferences.getInstance();
				final list = (prefs.getStringList(_webKey) ?? []);
				list.removeWhere((s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
				await prefs.setStringList(_webKey, list);
			} else {
				final db = await database;
				await db.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
			}
	}

	Future<void> incrementRetry(int id) async {
			if (kIsWeb) {
				final prefs = await SharedPreferences.getInstance();
				final list = (prefs.getStringList(_webKey) ?? []);
				final updated = list.map((s) {
					final m = jsonDecode(s) as Map<String, dynamic>;
					if (m['id'] == id) {
						m['retry_count'] = (m['retry_count'] as int) + 1;
						return jsonEncode(m);
					}
					return s;
				}).toList();
				await prefs.setStringList(_webKey, updated);
			} else {
				final db = await database;
				await db.rawUpdate(
					'UPDATE pending_ops SET retry_count = retry_count + 1 WHERE id = ?',
					[id],
				);
			}
	}
}

