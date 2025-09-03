import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_session.dart';
import 'account_mode_screen.dart';
import 'home_page.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    print('DEBUG - SignIn: Starting sign-in process');
    print('DEBUG - SignIn: Employee ID: "${_employeeIdCtrl.text.trim()}"');
    print('DEBUG - SignIn: Password: "${_passwordCtrl.text}"');
    
    setState(() => _loading = true);
    final session = Provider.of<UserSession>(context, listen: false);
    
    print('DEBUG - SignIn: Calling session.signInLocal()');
    final success = await session.signInLocal(
        _employeeIdCtrl.text.trim(), _passwordCtrl.text);
    
    print('DEBUG - SignIn: signInLocal returned: $success');
    setState(() => _loading = false);
    
    if (success) {
      print('DEBUG - SignIn: Success! Navigating to home...');
      try {
        // Alternative navigation approach
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MedicalHomeScreen()),
          (route) => false,
        );
        print('DEBUG - SignIn: Navigation completed successfully');
      } catch (e) {
        print('DEBUG - SignIn: Navigation error: $e');
      }
    } else {
      print('DEBUG - SignIn: Failed! Showing error message...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid credentials or local account not found')),
      );
    }
  }

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4ECDC4);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7FAFC), Color(0xFFE6FFFB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
              top: -60,
              right: -40,
              child: _blob(160, Colors.cyanAccent.withOpacity(.25))),
          Positioned(
              bottom: -50,
              left: -30,
              child: _blob(120, accent.withOpacity(.15))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, Color(0xFF9FFFFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 8))
                        ],
                      ),
                      child: const Icon(Icons.vaccines,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 18),
                    Text('Welcome back',
                        style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue. Or create a local account to use offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 22),

                    // Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12.withOpacity(.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8))
                        ],
                        border: Border.all(color: accent.withOpacity(.12)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _employeeIdCtrl,
                              decoration: InputDecoration(
                                labelText: 'Employee ID or Username',
                                prefixIcon: Icon(Icons.badge_outlined,
                                    color: Colors.grey[700]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: _inputBorder(),
                                enabledBorder: _inputBorder(),
                                focusedBorder: _focusBorder(),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: Colors.grey[700]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: _inputBorder(),
                                enabledBorder: _inputBorder(),
                                focusedBorder: _focusBorder(),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Text('Sign in',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AccountModeScreen())),
                      child: Text('New user? Sign up',
                          style: GoogleFonts.poppins(color: Colors.black87)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can use the app fully offline — signing up online is optional.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _inputBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      );

  OutlineInputBorder _focusBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 1.8),
      );

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
