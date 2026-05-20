import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/supabase_service.dart';
import '../services/biometric_service.dart';
import 'register_page.dart';

// Halaman login utama dengan email/password dan biometric auth.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = SupabaseService();

  final BiometricService _biometricService = BiometricService();
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color primaryGold = const Color(0xFFD4AF37);
  final Color bgDark = const Color(0xFF0A0A0A);
  final Color surfaceDark = const Color(0xFF161616);
  final Color errorRed = const Color(0xFFCF6679);

  // Buat transisi halaman dengan efek blur saat pindah ke register.
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

  // Autentikasi biometrik disinkronkan menggunakan service Anda agar stabil di mode rilis
  Future<void> _handleBiometricAuth() async {
    try {
      final bool canAuthenticate = await _biometricService.checkBiometrics();

      if (!canAuthenticate) {
        _showSnackBar(
          "Perangkat tidak mendukung biometrik atau sensor mati",
          isError: true,
        );
        return;
      }

      // Ambil data kredensial terenkripsi yang tersimpan dari login manual sebelumnya
      String? savedEmail = await _secureStorage.read(key: "saved_email");
      String? savedPassword = await _secureStorage.read(key: "saved_password");

      if (savedEmail == null || savedPassword == null) {
        _showSnackBar(
          "Silakan login manual dengan email & sandi terlebih dahulu sekali.",
          isError: true,
        );
        return;
      }

      // Memanggil fungsi autentikasi resmi dari BiometricService Anda
      final bool didAuthenticate = await _biometricService.authenticate();

      if (didAuthenticate) {
        if (!mounted) return;

        // Memasukkan data langsung ke controller di dalam setState
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
        });

        _showSnackBar("Sidik jari cocok! Memproses login...");

        // PERBAIKAN: Menggunakan addPostFrameCallback (lebih aman daripada Future.delayed untuk siklus render Flutter)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleLogin();
          }
        });
      }
    } catch (e) {
      _showSnackBar("Gagal memproses sidik jari perangkat", isError: true);
    }
  }

  // Proses login email/password dan simpan kredensial dengan aman.
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String inputEmail = _emailController.text.trim();
    final String inputPassword = _passwordController.text;

    try {
      await _apiService.signIn(email: inputEmail, password: inputPassword);

      // JIKA BERHASIL LOGIN SUPABASE: Amankan data ke local storage terenkripsi
      await _secureStorage.write(key: "saved_email", value: inputEmail);
      await _secureStorage.write(key: "saved_password", value: inputPassword);

      await _apiService.getCurrentUserProfile();

      if (mounted) {
        _showSnackBar("Selamat Datang kembali!");
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      String errorMsg = e.toString().toLowerCase();
      String displayMessage = "Terjadi kesalahan koneksi atau server";

      if (errorMsg.contains("invalid login credentials") ||
          errorMsg.contains("invalid credentials") ||
          errorMsg.contains("400") ||
          errorMsg.contains("not found")) {
        displayMessage = "Email atau Kata Sandi yang Anda masukkan salah.";
      } else if (errorMsg.contains("email not confirmed")) {
        displayMessage =
            "Email Anda belum dikonfirmasi. Silakan cek inbox email Anda.";
      } else if (errorMsg.contains("too many requests")) {
        displayMessage =
            "Terlalu banyak percobaan login. Silakan tunggu sebentar.";
      } else if (e is AuthException) {
        displayMessage = e.message;
      }

      _showSnackBar(displayMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tampilkan pesan umpan balik ke user menggunakan snackbar.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    // Ambil ukuran layar saat metode dipanggil untuk mencegah context crash di dalam properti margin
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

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
            ? errorRed.withOpacity(0.9)
            : Colors.green.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: EdgeInsets.only(
          bottom: screenHeight * 0.05,
          left: screenWidth > 600 ? screenWidth * 0.3 : 20,
          right: screenWidth > 600 ? screenWidth * 0.3 : 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['autoTriggerBiometric'] == true) {
        _handleBiometricAuth();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      _buildLogoSection(),
                      const SizedBox(height: 25),
                      _buildHeaderSection(),
                      const SizedBox(height: 25),
                      _buildSlimTextField(
                        label: "EMAIL",
                        controller: _emailController,
                        hint: "Masukkan email anda",
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Email tidak boleh kosong";
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return "Format email tidak valid";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildSlimTextField(
                        label: "KATA SANDI",
                        controller: _passwordController,
                        hint: "Masukkan kata sandi",
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Kata sandi tidak boleh kosong";
                          }
                          if (value.length < 6) {
                            return "Kata sandi minimal 6 karakter";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 35),
                      _buildActionButtonsRow(),
                      const SizedBox(height: 25),
                      _buildFooterLink(),
                    ],
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
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
          "Selamat Datang",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Masuk untuk melanjutkan sesi podcast",
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
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
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
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorRed.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsRow() {
    const double targetHeight = 54.0;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SizedBox(
            height: targetHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: Colors.black,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _handleLogin,
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
                      "MASUK SEKARANG",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _isLoading ? null : _handleBiometricAuth,
          child: Container(
            width: targetHeight,
            height: targetHeight,
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryGold.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              color: primaryGold,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "belum punya akun? ",
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.push(context, _createBlurRoute(const RegisterPage())),
          child: Text(
            "Daftar",
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
