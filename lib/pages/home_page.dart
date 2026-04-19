import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'reservasi_page.dart';
import 'admin_page.dart';
import 'profile_page.dart';
import 'rincian_peminjaman_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseService _apiService = SupabaseService();
  String? role;
  String? email;
  String? name;
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

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final user = _apiService.currentUser;
      final profile = await _apiService.getCurrentUserProfile();

      if (mounted) {
        setState(() {
          email = user?.email;
          name = (profile != null && profile['name'] != null)
              ? profile['name']
              : (user?.userMetadata?['full_name'] ?? "Mahasiswa");

          role = profile != null
              ? profile['role'].toString().toLowerCase().trim()
              : 'mahasiswa';
        });

        if (role == 'admin') {
          await _fetchAdminStats();
        }

        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
                      // --- BAGIAN STATIS (TIDAK IKUT SCROLL) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(),
                            SizedBox(height: screenHeight * 0.10),
                            _buildHeroText(),
                            const SizedBox(height: 60),
                            _buildLargeProfileCard(),
                            const SizedBox(height: 20),
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

  Widget _buildCinematicBackground(double height) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height * 0.65,
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
                  Colors.black.withOpacity(0.85),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGold.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: primaryGold, size: 14),
                SizedBox(width: 8),
                Text(
                  "FEB UNMUL",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _fetchUserData,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ).then((_) => _fetchUserData()),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryGold.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: surfaceDark,
                    child: Text(
                      name != null && name!.isNotEmpty
                          ? name![0].toUpperCase()
                          : "M",
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: primaryGold, width: 3)),
          ),
          child: const Text(
            "STUDIO PODCAST",
            style: TextStyle(
              color: primaryGold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Ruang Kreativitas",
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w200,
            height: 1,
          ),
        ),
        const Text(
          "Masa Depan",
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildLargeProfileCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
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
                        fontSize: 18,
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
                padding: const EdgeInsets.all(4),
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

  Widget _buildMenuLogic() {
    if (role == 'admin') {
      return Column(
        children: [
          _buildStatsCard(),
          const SizedBox(height: 15),
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
