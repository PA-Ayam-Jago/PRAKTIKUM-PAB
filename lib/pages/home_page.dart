import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import 'reservasi_page.dart';
import 'admin_page.dart';
import 'profile_page.dart';
import 'rincian_peminjaman_page.dart';

// Halaman utama aplikasi: menampilkan profil, akses reservasi, dan dashboard admin.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// State user dan tampilan di homepage.
class _HomePageState extends State<HomePage> {
  final SupabaseService _apiService = SupabaseService();

  String? role;
  String? email;
  String? name;
  String? profileImageUrl;
  bool isLoading = true;
  int totalReservasiBulanIni = 0;

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color bgDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF161616);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Buka Google Maps dengan rute langsung ke lokasi FEB Unmul.
  Future<void> _openGoogleMaps() async {
    const String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&destination=FEB+Universitas+Mulawarman&origin=My+Location";
    final Uri url = Uri.parse(googleMapsUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // Muat data user dan role untuk menentukan tampilan menu.
  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final user = _apiService.currentUser;
      final profile = await _apiService.getCurrentUserProfile();

      if (mounted) {
        setState(() {
          email = user?.email;
          name = profile?['name'] ?? user?.userMetadata?['full_name'] ?? "User";

          final String? rawUrl = profile?['avatar_url'];

          if (rawUrl != null && rawUrl.trim().isNotEmpty) {
            profileImageUrl =
                "$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}";
          } else {
            profileImageUrl = null;
          }

          role = profile != null
              ? profile['role'].toString().toLowerCase().trim()
              : 'mahasiswa';
        });

        if (role == 'admin') await _fetchAdminStats();
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Ambil statistik admin jika user memiliki role admin.
  Future<void> _fetchAdminStats() async {
    try {
      final total = await _apiService.getTotalReservasiBulanIni();
      if (mounted) {
        setState(() {
          totalReservasiBulanIni = total;
        });
      }
    } catch (e) {
      debugPrint("Error Fetching Stats: $e");
    }
  }

  // Build UI utama homepage dengan background, profil, dan menu.
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgDark,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGold))
          : Stack(
              children: [
                _buildCinematicBackground(screenHeight),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(),
                            SizedBox(
                              height: screenHeight * 0.07,
                            ), // Disesuaikan agar responsif dan tidak overflow
                            _buildHeroText(),
                            const SizedBox(height: 45),
                            _buildLargeProfileCard(),
                            const SizedBox(height: 30),
                            _buildSectionLabel("LAYANAN UTAMA"),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                          child: Column(
                            children: [
                              _buildMenuLogic(),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Background efek sinematik di bagian atas halaman.
  Widget _buildCinematicBackground(double height) {
    return Positioned(
      top: 2,
      left: 0,
      right: 0,
      height: height * 0.58,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Background_FEB1.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: bgDark),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.99),
                  Colors.transparent,
                  bgDark,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.7)],
                stops: [0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bar atas berisi branding, tombol lokasi, refresh, dan avatar kecil.
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.5,
                  ), // Diperbarui ke .withValues
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryGold.withValues(alpha: 0.5),
                  ), // Diperbarui ke .withValues
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: primaryGold, size: 10),
                    SizedBox(
                      width: 8,
                    ), // PERBAIKAN: STheme yang error diganti dengan SizedBox bersih
                    Text(
                      "FEB UNMUL",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _openGoogleMaps,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.09,
                    ), // Diperbarui ke .withValues
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ), // Diperbarui ke .withValues
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: primaryGold,
                        size: 12,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Cek Lokasi Studio",
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _fetchUserData,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ).then((_) => _fetchUserData()),
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryGold.withValues(
                        alpha: 0.7,
                      ), // Diperbarui ke .withValues
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: surfaceDark,
                    foregroundImage: (profileImageUrl != null)
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: Text(
                      name != null && name!.isNotEmpty
                          ? name![0].toUpperCase()
                          : "U",
                      style: const TextStyle(
                        color: primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: primaryGold, width: 3)),
          ),
          child: const Text(
            "STUDIO PODCAST",
            style: TextStyle(
              color: primaryGold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          "Ruang Kreativitas",
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w200,
            height: 1.2,
          ),
        ),
        const Text(
          "Masa Depan",
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // Kartu profil user besar yang menampilkan nama, email, dan avatar kotak.
  Widget _buildLargeProfileCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black54,
                ),
                // PERBAIKAN LOGIKA: Menggunakan ClipRRect + Image.network dengan errorBuilder
                // agar ketika error/gagal load, state global profileImageUrl tidak dipaksa null secara permanen.
                child: profileImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.mic_none_rounded,
                              color: primaryGold,
                              size: 28,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.mic_none_rounded,
                        color: primaryGold,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? "Memuat...",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email ?? "user@unmul.ac.id",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: primaryGold,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logika menu utama: tampilkan menu admin atau reservasi biasa.
  Widget _buildMenuLogic() {
    if (role == 'admin') {
      return Column(
        children: [
          _buildStatsCard(),
          const SizedBox(height: 10),
          _buildLargeMenuCard(
            title: "Monitoring Admin",
            subtitle: "Kelola jadwal & status reservasi",
            icon: Icons.analytics_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPage()),
            ).then((_) => _fetchUserData()),
          ),
        ],
      );
    } else {
      return _buildLargeMenuCard(
        title: "Reservasi Studio",
        subtitle: "Booking jadwal rekaman kamu",
        icon: Icons.calendar_today_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReservasiPage()),
        ),
      );
    }
  }

  // Kartu statistik total reservasi bulanan untuk admin.
  Widget _buildStatsCard() {
    final String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RincianPeminjamanPage()),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryGold.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Total Peminjaman",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: primaryGold,
                      size: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currentMonth.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalReservasiBulanIni.toString(),
                  style: const TextStyle(
                    color: primaryGold,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6, left: 6),
                  child: Text(
                    "SESI",
                    style: TextStyle(
                      color: primaryGold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Kartu menu besar untuk navigasi ke fitur utama.
  Widget _buildLargeMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryGold, size: 30),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: primaryGold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Label section kecil untuk memisahkan area menu.
  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
      ],
    );
  }
}
