import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'local_signup_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountModeScreen extends StatelessWidget {
  const AccountModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4ECDC4);
    return Scaffold(
      appBar: AppBar(
          title: Text('Create an account', style: GoogleFonts.poppins())),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFF7FAFC), Color(0xFFE6FFFB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text('Choose how you want to create your account',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey[800])),
              const SizedBox(height: 20),

              // Online card
              _optionCard(
                context: context,
                leadingBg: accent,
                leadingIcon: Icons.cloud_outlined,
                title: 'Sign up online (sync later)',
                subtitle: 'Create an online account to sync with our servers',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegistrationScreen())),
              ),
              const SizedBox(height: 12),

              // Local card
              _optionCard(
                context: context,
                leadingBg: Colors.deepOrangeAccent,
                leadingIcon: Icons.phone_android,
                title: 'Stay local (offline-only)',
                subtitle:
                    'Create a minimal local account stored on this device',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LocalSignupScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required BuildContext context,
    required Color leadingBg,
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                  backgroundColor: leadingBg,
                  child: Icon(leadingIcon, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
