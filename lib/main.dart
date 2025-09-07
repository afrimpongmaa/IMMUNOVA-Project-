import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:immunova/Screens/onboarding_screen.dart';
import 'services/sync_service.dart';

const String _supabaseUrl = 'https://xrvntkufeisfdujjzxrn.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhydm50a3VmZWlzZmR1amp6eHJuIiwicm9zZSI6ImFub24iLCJpYXQiOjE3NTcwODM4MjQsImV4cCI6MjA3MjY1OTgyNH0.OO4uNfBMxqiYA2G1NbmIgzvFeHbuR2OnVSjL05KUH9E';

// Allow overrides from --dart-define
const String _envSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _envSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
final String _resolvedSupabaseUrl = _envSupabaseUrl.isNotEmpty
    ? _envSupabaseUrl
    : _supabaseUrl;
final String _resolvedSupabaseAnonKey = _envSupabaseAnonKey.isNotEmpty
    ? _envSupabaseAnonKey
    : _supabaseAnonKey;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Basic sanity logs to help diagnose "invalid api key"
  assert(() {
    if (!_resolvedSupabaseAnonKey.startsWith('eyJ')) {
      // All Supabase JWT keys are base64 strings starting with eyJ...
      debugPrint(
        '[Supabase] The provided anon key does not look valid. Check Dashboard → Settings → API.',
      );
    }
    if (!_resolvedSupabaseUrl.contains('.supabase.co')) {
      debugPrint(
        '[Supabase] The Supabase URL seems incorrect. It should look like https://xxxx.supabase.co',
      );
    }
    return true;
  }());

  await Supabase.initialize(
    url: _resolvedSupabaseUrl,
    anonKey: _resolvedSupabaseAnonKey,
    // Ensure every request carries the API key header
    headers: {'apikey': _resolvedSupabaseAnonKey},
  );
  runApp(const ImmunovaApp());
}

class ImmunovaApp extends StatelessWidget {
  const ImmunovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immunova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: GoogleFonts.poppins().fontFamily),
      home: Builder(
        builder: (context) {
          // Start connectivity/watchers after MaterialApp has an Overlay
          SyncService.instance.start(context);
          return const OnboardingScreen();
        },
      ),
    );
  }
}
