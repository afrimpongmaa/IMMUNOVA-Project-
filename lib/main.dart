import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_session.dart';
import 'screens/onboarding_screen.dart';
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
