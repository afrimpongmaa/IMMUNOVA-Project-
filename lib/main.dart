import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_session.dart';
import 'Screens/onboarding_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final dbHelper = DatabaseHelper();
  try {
    // Reset database during development if needed
    // await dbHelper.resetDatabase();

    final isInitialized = await dbHelper.isDatabaseInitialized();
    if (!isInitialized) {
      await dbHelper.database;
      print('Database initialized successfully');
    }
    
    // Check if we need to create a default test user
    final existingUsers = await dbHelper.getAll('users');
    if (existingUsers.isEmpty) {
      print('No users found, creating test user...');
      final testUser = {
        'full_name': 'Test Doctor',
        'phone_number': '+1234567890',
        'employee_id': 'test123',
        'password': 'password',
        'hospital_name': 'Test Hospital',
        'created_at': DateTime.now().toIso8601String(),
      };
      await dbHelper.insert('users', testUser);
      print('Test user created - Employee ID: test123, Password: password');
    }
  } catch (e) {
    print('Error initializing database: $e');
  }

  final session = UserSession();
  await session.loadFromPrefs(); // load persisted session if any
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseHelper>.value(value: dbHelper),
        ChangeNotifierProvider<UserSession>.value(value: session),
      ],
      child: const ImmunovaApp(),
    ),
  );
}

class ImmunovaApp extends StatelessWidget {
  const ImmunovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immunova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: GoogleFonts.poppins().fontFamily),
      home: const OnboardingScreen(),
    );
  }
}
