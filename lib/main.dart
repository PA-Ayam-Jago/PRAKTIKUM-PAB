import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/admin_page.dart';
import 'pages/profile_page.dart';
import 'pages/reservasi_page.dart';

void main() async {
  // Memastikan binding Flutter siap sebelum menjalankan fungsi async
  WidgetsFlutterBinding.ensureInitialized();

  // PERBAIKAN: Membungkus dotenv ke dalam try-catch global yang lebih ketat
  // Jika .env gagal dimuat di mode rilis, aplikasi tidak akan crash/stuck hitam.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Peringatan: Gagal memuat file .env: $e");
  }

  // PERBAIKAN UTAMA: Inisialisasi Supabase disesuaikan.
  // Menghapus 'EmptyLocalStorage()' agar Supabase dapat menggunakan penyimpanan lokal bawaannya.
  // Ini membuat sesi login user tersimpan dengan aman dan sinkron dengan logika SplashPage.
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint("Eror Fatal: Gagal menginisialisasi Supabase: $e");
  }

  // Kunci orientasi aplikasi ke mode potret.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root widget aplikasi dengan tema gelap dan konfigurasi rute.
  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0A0A0A);
    const Color primaryGold = Color(0xFFD4AF37);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Studio FEB Universitas Mulawarman',
      debugShowCheckedModeBanner: false,

      // Tema global aplikasi menggunakan warna gelap dan emas.
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        canvasColor: bgDark,
        primaryColor: primaryGold,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: const ColorScheme.dark(
          primary: primaryGold,
          onPrimary: Colors.black,
          secondary: Color(0xFF2E7D32),
        ),
        fontFamily: 'Inter',
      ),

      // Menggunakan initialRoute agar manajemen transisi argumen antar rute berjalan mulus
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashPage(), // Halaman awal splash screen
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminPage(),
        '/profile': (context) => const ProfilePage(),
        '/reservasi': (context) => const ReservasiPage(),
      },
    );
  }
}
