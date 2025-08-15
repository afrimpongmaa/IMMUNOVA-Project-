import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class UserSession extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;

  int? get localId =>
      _currentUser != null ? (_currentUser!['local_id'] as int?) : null;
  String? get displayName =>
      _currentUser != null ? (_currentUser!['full_name'] as String?) : null;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('current_local_user_id');
    if (id != null) {
      final user = await _db.getById('users', id);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }

  Future<bool> signInLocal(String employeeIdOrUsername, String password) async {
    try {
      final users =
          await _db.queryByIndex('users', 'employee_id', employeeIdOrUsername);
      if (users.isEmpty) return false;
      final user = users.first;
      final stored = (user['password'] ?? '') as String;
      if (stored == password) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_local_user_id', user['local_id'] as int);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<int?> registerLocal(Map<String, dynamic> userMap) async {
    // Inserts into 'users' store and sets session
    final localId = await _db.insert('users', userMap);
    final created = await _db.getById('users', localId);
    if (created != null) {
      _currentUser = created;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_local_user_id', localId);
      notifyListeners();
      return localId;
    }
    return null;
  }

  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_local_user_id');
    notifyListeners();
  }
}
