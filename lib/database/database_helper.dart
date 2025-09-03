import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart' if (dart.library.io) 'package:idb_shim/idb_io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static IdbFactory? _idbFactory;
  static Database? _database;
  static const String dbName = 'immunova_db';
  static const int dbVersion = 1;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal() {
    if (kIsWeb) {
      _idbFactory = idbFactoryBrowser;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (_idbFactory == null) {
      throw Exception('IndexedDB not supported in this environment');
    }

    // Use dbVersion constant
    return await _idbFactory!.open(dbName,
      version: dbVersion,
      onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;

        // Create stores if they don't exist
        if (!db.objectStoreNames.contains('patients')) {
          final patientsStore = db.createObjectStore('patients',
              keyPath: 'local_id', autoIncrement: true);
          patientsStore.createIndex('remote_id', 'remote_id', unique: true);
          patientsStore.createIndex('doc_id', 'doc_id', unique: false);
        }

        if (!db.objectStoreNames.contains('immunizations')) {
          final immunizationsStore = db.createObjectStore('immunizations',
              keyPath: 'local_id', autoIncrement: true);
          immunizationsStore.createIndex(
              'patient_id', 'patient_id', unique: false);
          immunizationsStore.createIndex(
              'vaccine_id', 'vaccine_id', unique: false);
        }

        if (!db.objectStoreNames.contains('vaccines')) {
          final vaccinesStore = db.createObjectStore('vaccines',
              keyPath: 'local_id', autoIncrement: true);
          vaccinesStore.createIndex('name', 'name', unique: true);
        }

        if (!db.objectStoreNames.contains('notifications')) {
          final notificationsStore = db.createObjectStore('notifications',
              keyPath: 'local_id', autoIncrement: true);
          notificationsStore.createIndex('user_id', 'user_id', unique: false);
          notificationsStore.createIndex(
              'patient_id', 'patient_id', unique: false);
        }

        if (!db.objectStoreNames.contains('user_settings')) {
          final settingsStore = db.createObjectStore('user_settings',
              keyPath: 'local_id', autoIncrement: true);
          settingsStore.createIndex('user_id', 'user_id', unique: true);
        }

        if (!db.objectStoreNames.contains('users')) {
          final usersStore = db.createObjectStore('users',
              keyPath: 'local_id', autoIncrement: true);
          usersStore.createIndex('remote_id', 'remote_id', unique: true);
          usersStore.createIndex('employee_id', 'employee_id', unique: true);
        }
      });
  }

  // Helper methods (improved)
  Future<int> insert(String storeName, Map<String, dynamic> data) async {
    final db = await database;
    final txn = db.transaction(storeName, 'readwrite');
    final store = txn.objectStore(storeName);

    // If data already contains keyPath 'local_id' use put, otherwise add.
    if (data.containsKey('local_id')) {
      await store.put(data);
      await txn.completed;
      return data['local_id'] as int;
    } else {
      final id = await store.add(data);
      await txn.completed;
      // id could be num; ensure int
      return (id is int) ? id : (id as num).toInt();
    }
  }

  Future<Map<String, dynamic>?> getById(
      String storeName, int localId) async {
    final db = await database;
    final txn = db.transaction(storeName, 'readonly');
    final store = txn.objectStore(storeName);
    final record = await store.getObject(localId);
    await txn.completed;
    if (record == null) return null;
    return Map<String, dynamic>.from(record as Map);
  }

  Future<List<Map<String, dynamic>>> queryByIndex(
      String storeName, String indexName, dynamic key) async {
    final db = await database;
    final txn = db.transaction(storeName, 'readonly');
    final store = txn.objectStore(storeName);
    final index = store.index(indexName);
    final List<Map<String, dynamic>> results = [];
    
    print('DEBUG - Querying store: $storeName, index: $indexName, key: $key');
    
    try {
      await for (final cursor in index.openCursor(range: key == null ? null : KeyRange.only(key))) {
        if (cursor.value is Map) {
          final result = Map<String, dynamic>.from(cursor.value as Map);
          print('DEBUG - Found record: $result');
          results.add(result);
        }
      }
      
      print('DEBUG - Cursor iteration completed');
      // Remove the txn.completed await for readonly transactions
      
      print('DEBUG - Total results found: ${results.length}');
      return results;
    } catch (e) {
      print('DEBUG - Error in queryByIndex: $e');
      return results;
    }
  }

  Future<void> delete(String storeName, int localId) async {
    final db = await database;
    final txn = db.transaction(storeName, 'readwrite');
    final store = txn.objectStore(storeName);
    await store.delete(localId);
    await txn.completed;
  }

  Future<void> update(String storeName, Map<String, dynamic> data, int localId) async {
    final db = await database;
    final txn = db.transaction(storeName, 'readwrite');
    final store = txn.objectStore(storeName);

    // ensure keyPath is present for put
    data['local_id'] = localId;
    await store.put(data);
    await txn.completed;
  }
  
  // Add method to check if database is initialized
  Future<bool> isDatabaseInitialized() async {
    try {
      final db = await database;
      return db.objectStoreNames.contains('patients');
    } catch (e) {
      return false;
    }
  }

  // Add method to reset database (useful for development)
  Future<void> resetDatabase() async {
    if (_database != null) {
      _database!.close(); // close() is synchronous/void
      _database = null;
    }
    if (_idbFactory != null) {
      await _idbFactory!.deleteDatabase(dbName);
    }
  }

  // Added: getAll - return all records from an object store as List<Map>
  Future<List<Map<String, dynamic>>> getAll(String storeName) async {
    final db = await database;
    final txn = db.transaction(storeName, 'readonly');
    final store = txn.objectStore(storeName);
    final List<Map<String, dynamic>> results = [];

    // iterate all records
    await for (final cursor in store.openCursor(autoAdvance: true)) {
      if (cursor.value is Map) {
        results.add(Map<String, dynamic>.from(cursor.value as Map));
      }
    }

    await txn.completed;
    return results;
  }
}
