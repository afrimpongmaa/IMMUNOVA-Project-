import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_session.dart';
import 'home_page.dart';

class LocalSignupScreen extends StatefulWidget {
  const LocalSignupScreen({Key? key}) : super(key: key);

  @override
  State<LocalSignupScreen> createState() => _LocalSignupScreenState();
}

class _LocalSignupScreenState extends State<LocalSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _employeeIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _signupLocal(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final userMap = {
      'full_name': _nameCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      'employee_id': _employeeIdCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'hospital_name': '',
      'created_at': DateTime.now().toIso8601String(),
    };
    final session = Provider.of<UserSession>(context, listen: false);
    final localId = await session.registerLocal(userMap);
    setState(() => _saving = false);
    if (localId != null) {
      // Success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF4ECDC4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                'Account created successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Continue', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );

      // Go to home page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MedicalHomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create local account')));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFF7FAFC), Color(0xFFE6FFFB)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text('Create a local account',
                      style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withOpacity(.12)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12.withOpacity(.06),
                            blurRadius: 16,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _field(
                              controller: _nameCtrl,
                              label: 'Full name',
                              icon: Icons.person_outline),
                          const SizedBox(height: 12),
                          _field(
                              controller: _phoneCtrl,
                              label: 'Phone',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _field(
                              controller: _employeeIdCtrl,
                              label: 'Employee ID',
                              icon: Icons.badge_outlined),
                          const SizedBox(height: 12),
                          _field(
                              controller: _passwordCtrl,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscure: true),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _saving ? null : () => _signupLocal(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Create local account',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        filled: true,
        fillColor: Colors.grey[50],
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _focusBorder(),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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
