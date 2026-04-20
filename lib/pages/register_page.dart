import 'dart:ui';
import 'login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final SupabaseService _apiService = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color primaryGold = const Color(0xFFD4AF37);
  final Color bgDark = const Color(0xFF0A0A0A);
  final Color surfaceDark = const Color(0xFF161616);

  Route _createBlurRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: (1 - animation.value) * 20,
              sigmaY: (1 - animation.value) * 20,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Konfirmasi kata sandi tidak cocok", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: "-",
      );

      if (mounted) {
        _showSnackBar("Registrasi Berhasil! Silakan masuk.");
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on AuthException catch (e) {
      String errorMessage = e.message;
      String msg = e.message.toLowerCase();

      if (msg.contains("already registered") ||
          msg.contains("user already exists")) {
        errorMessage = "Email sudah terdaftar. Gunakan email lain.";
      } else if (msg.contains("weak password")) {
        errorMessage = "Kata sandi terlalu lemah (minimal 6 karakter).";
      }
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      String errorText = e.toString();
      if (errorText.contains("row-level security")) {
        errorText =
            "Gagal menyimpan profil. Pastikan RLS Policy INSERT sudah aktif.";
      }
      _showSnackBar("Terjadi kesalahan: $errorText", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.redAccent.withOpacity(0.9)
            : Colors.green.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background_FEB.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgDark.withOpacity(0.4),
                      bgDark.withOpacity(0.7),
                      bgDark,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 40, right: 20, child: _buildTopLogo()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        _buildLogoSection(),
                        const SizedBox(height: 25),
                        _buildHeaderSection(),
                        const SizedBox(height: 25),
                        _buildSlimTextField(
                          label: "NAMA LENGKAP",
                          controller: _nameController,
                          hint: "Masukkan nama lengkap anda",
                          icon: Icons.person_outline_rounded,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? "Nama wajib diisi"
                              : null,
                        ),
                        const SizedBox(height: 15),
                        _buildSlimTextField(
                          label: "EMAIL",
                          controller: _emailController,
                          hint: "Masukkan email anda",
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "Email wajib diisi";
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value.trim()))
                              return "Format email tidak valid";
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildSlimTextField(
                          label: "KATA SANDI",
                          controller: _passwordController,
                          hint: "Minimal 6 karakter",
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: (value) =>
                              (value == null || value.length < 6)
                              ? "Minimal 6 karakter"
                              : null,
                        ),
                        const SizedBox(height: 15),
                        _buildSlimTextField(
                          label: "KONFIRMASI KATA SANDI",
                          controller: _confirmPasswordController,
                          hint: "Ulangi kata sandi",
                          icon: Icons.lock_reset_rounded,
                          isPassword: true,
                          validator: (value) => value == null || value.isEmpty
                              ? "Konfirmasi wajib diisi"
                              : null,
                        ),
                        const SizedBox(height: 35),
                        _buildCompactButton(),
                        const SizedBox(height: 25),
                        _buildFooterLink(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLogo() {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset('assets/images/Logo_FEB.jpeg', fit: BoxFit.contain),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryGold, width: 1.5),
            color: Colors.black.withOpacity(0.3),
          ),
          child: Icon(Icons.mic_none_rounded, color: primaryGold, size: 35),
        ),
        const SizedBox(height: 12),
        const Text(
          "FEB STUDIO",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        const Text(
          "Gabung ke Studio",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Buat akun untuk memesan jadwal podcast",
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSlimTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: primaryGold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 18),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[500],
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: surfaceDark.withOpacity(0.9),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: primaryGold.withOpacity(0.6),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _handleRegister,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "DAFTAR SEKARANG",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "sudah punya akun? ",
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).pushReplacement(_createBlurRoute(const LoginPage()));
          },
          child: Text(
            "Masuk",
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
