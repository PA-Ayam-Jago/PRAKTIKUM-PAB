import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Ditambahkan untuk cek data sidik jari
import '../services/supabase_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // Animasi Splash screen: skala, fade, dan pergeseran logo.
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _slideAnimation;

  final _apiService = SupabaseService();

  // PERBAIKAN: Menambahkan opsi enkripsi Shared Preferences khusus Android
  // agar proses pembacaan storage tidak membeku (stuck) pada beberapa versi OS Android di mode rilis.
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Siapkan animasi splash, kemudian mulai alur inisialisasi aplikasi.
    _setupAnimations();
    _initializeApp();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/Opening_FEB.jpeg'),
        context,
      );
    });
  }

  // Konfigurasi kurva animasi untuk efek masuk logo dan teks.
  void _setupAnimations() {
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  // LOGIKA DIPERBAIK: Mengatur alur routing cerdas setelah splash screen
  // Jalankan splash screen dan tentukan rute berikutnya setelah delay dengan penanganan Error Global (Try-Catch).
  Future<void> _initializeApp() async {
    _controller.forward();

    // Memastikan durasi animasi splash berjalan penuh selama 4 detik
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // PERBAIKAN UTAMA: Membungkus alur pengecekan sesi & penyimpanan lokal ke dalam try-catch.
    // Jika koneksi internet Supabase gagal memuat atau Secure Storage mengalami kendala enkripsi di perangkat,
    // aplikasi tidak akan stuck (freeze), melainkan dialihkan secara aman ke halaman login.
    try {
      // Cek apakah user saat ini masih memiliki sesi aktif di Supabase
      final user = _apiService.currentUser;

      // Cek ketersediaan data kredensial sidik jari di Secure Storage lokal dengan batas waktu (timeout) 2 detik
      String? savedEmail = await _secureStorage
          .read(key: "saved_email")
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      String? savedPassword = await _secureStorage
          .read(key: "saved_password")
          .timeout(const Duration(seconds: 2), onTimeout: () => null);

      if (!mounted) return;

      if (user == null) {
        // SITUASI 1: Tidak ada sesi aktif di Supabase (Belum login / Sudah pernah logout)
        if (savedEmail != null && savedPassword != null) {
          // Punya data sidik jari: Arahkan ke Login dan kirim argumen pemicu otomatis
          Navigator.pushReplacementNamed(
            context,
            '/login',
            arguments: {'autoTriggerBiometric': true},
          );
        } else {
          // Pengguna baru/belum pernah login sama sekali: Masuk ke halaman login biasa
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // SITUASI 2: Sesi login Supabase masih aktif (Keluar total tanpa logout)
        // Demi keamanan dan estetika alur navigasi, kita arahkan pengguna kembali ke LoginPage.
        // Jika mereka memiliki data sidik jari, sensor biometrik akan otomatis dipicu untuk membuka kunci rute utama.
        if (savedEmail != null && savedPassword != null) {
          Navigator.pushReplacementNamed(
            context,
            '/login',
            arguments: {'autoTriggerBiometric': true},
          );
        } else {
          // Jika sesi aktif di Supabase tapi tidak ada data lokal, validasikan ulang profilnya ke halaman utama
          try {
            final profile = await _apiService.getCurrentUserProfile();

            if (!mounted) return;

            if (profile != null && profile['role'] == 'admin') {
              Navigator.pushReplacementNamed(context, '/admin');
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } catch (e) {
            // Jika terjadi kendala jaringan saat memuat ulang profil, kembalikan aman ke login
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      }
    } catch (e) {
      // Backup system: Jika terjadi kegagalan sistem sistemik, lempar langsung ke halaman login agar tidak stuck hitam/putih.
      debugPrint("Terjadi kesalahan inisialisasi awal: $e");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Buat UI splash screen dengan status bar transparan.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi logo utama di tengah splash.
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Image.asset(
                  'assets/images/Opening_FEB1.jpeg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Teks judul dan baris bawah yang tampil setelah logo.
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const Text(
                      "FAKULTAS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const Text(
                      "EKONOMI DAN BISNIS",
                      style: TextStyle(
                        color: Color(0xFFFBC02D),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 250,
                      height: 3,
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "UNIVERSITAS MULAWARMAN",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
