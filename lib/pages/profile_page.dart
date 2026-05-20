import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Untuk manajemen hapus kredensial aman
import '../services/supabase_service.dart';
import 'dart:async';

// Halaman profil: menampilkan dan mengedit data user, avatar, dan logout.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// State profil: mengelola foto, data profil, sensor guncangan, dan autentikasi.
class _ProfilePageState extends State<ProfilePage> {
  final SupabaseService _apiService = SupabaseService();
  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage(); // Instance storage aman

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = true;
  String? _avatarUrl;
  Uint8List? _selectedFileBytes;
  String? _selectedFileExt;

  StreamSubscription? _accelSubscription;

  double _lastX = 0;
  double _lastY = 0;
  double _lastZ = 0;

  DateTime _lastShakeTime = DateTime.now();
  bool _isDialogShowing =
      false; // LOGIKA BARU: Pengunci agar dialog tidak tumpang tindih

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color bgDark = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color errorRed = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initShakeSensor();
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();

    _nameController.dispose();
    _deskripsiController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  // Aktifkan deteksi guncangan untuk hapus foto avatar.
  void _initShakeSensor() {
    _accelSubscription?.cancel();

    _accelSubscription = accelerometerEvents.listen((event) {
      if (!mounted) return;

      final now = DateTime.now();

      // hitung perubahan gerakan
      double deltaX = (event.x - _lastX).abs();
      double deltaY = (event.y - _lastY).abs();
      double deltaZ = (event.z - _lastZ).abs();

      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;

      double force = deltaX + deltaY + deltaZ;

      // anti spam trigger (1.5 detik cooldown)
      if (now.difference(_lastShakeTime).inMilliseconds < 1500) return;

      // threshold shake (bisa disesuaikan)
      if (force > 14 && force < 80) {
        _lastShakeTime = now;

        final hasAvatar =
            _selectedFileBytes != null ||
            (_avatarUrl?.trim().isNotEmpty ?? false);

        if (!_isDialogShowing && hasAvatar) {
          _confirmClearPhoto();
        }
      }
    });
  }

  // Dialog konfirmasi hapus foto saat ponsel diguncang.
  void _confirmClearPhoto() {
    if (!mounted) return;

    setState(() => _isDialogShowing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Hapus Foto?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Guncangan terdeteksi. Ingin menghapus atau reset foto profil ini?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _isDialogShowing = false);
              Navigator.pop(context);
            },
            child: const Text("BATAL", style: TextStyle(color: Colors.grey)),
          ),

          TextButton(
            onPressed: () async {
              setState(() => _isDialogShowing = false);
              Navigator.pop(context);

              setState(() {
                _selectedFileBytes = null;
                _selectedFileExt = null;
              });

              await _removeProfilePhoto();

              if (mounted) {
                _showSnackBar("Foto profil direset", isError: false);
              }
            },
            child: const Text(
              "HAPUS",
              style: TextStyle(color: errorRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isDialogShowing = false);
      }
    });
  }

  Future<void> _removeProfilePhoto() async {
    try {
      final user = _apiService.currentUser;
      if (user == null) return;

      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        final path = _avatarUrl!.split('/avatars/').last;

        await _apiService.client.storage.from('avatars').remove([path]);
      }

      await _apiService.client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          _avatarUrl = null;
        });
      }
    } catch (e) {
      _showSnackBar("Gagal menghapus foto", isError: true);
    }
  }

  // Muat data profil user dari Supabase.
  Future<void> _loadProfileData() async {
    try {
      final user = _apiService.currentUser;
      if (!mounted || user == null) return;

      _emailController.text = user.email ?? "";
      final userData = await _apiService.getUserModel(user.id);

      if (mounted) {
        setState(() {
          if (userData != null) {
            _nameController.text = userData.name;
            _deskripsiController.text = userData.phone;
            _avatarUrl = userData.avatarUrl;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Ambil gambar dari kamera atau galeri.
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 50,
    );

    if (image == null) return;

    final Uint8List bytes = await image.readAsBytes();

    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      _showSnackBar("Ukuran gambar maksimal 2MB", isError: true);
      return;
    }

    final String extension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : 'jpg';

    final allowedExt = ['jpg', 'jpeg', 'png'];

    if (!allowedExt.contains(extension)) {
      _showSnackBar("Format gambar harus JPG atau PNG", isError: true);
      return;
    }

    if (!mounted) return;

    setState(() {
      _selectedFileBytes = bytes;
      _selectedFileExt = extension;
    });
  }

  // Modal untuk pilih sumber foto: kamera atau galeri.
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          border: Border(top: BorderSide(color: primaryGold, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "PILIH SUMBER FOTO",
              style: TextStyle(
                color: primaryGold,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceItem(
                  icon: Icons.camera_enhance_rounded,
                  label: "Kamera",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceItem(
                  icon: Icons.photo_library_rounded,
                  label: "Galeri",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Item tombol untuk sumber foto (kamera atau galeri).
  Widget _buildSourceItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryGold, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simpan profil ke Supabase dengan upload avatar jika ada.
  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar("Nama tidak boleh kosong", isError: true);
      return;
    }

    if (_nameController.text.trim().length < 3) {
      _showSnackBar("Nama terlalu pendek", isError: true);
      return;
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(_nameController.text.trim())) {
      _showSnackBar("Nama hanya boleh berisi huruf", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalAvatarUrl = _avatarUrl;

      if (_selectedFileBytes != null) {
        finalAvatarUrl = await _apiService.uploadAvatar(
          fileBytes: _selectedFileBytes!,
          extension: _selectedFileExt ?? 'jpg',
        );
      }

      await _apiService.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _deskripsiController.text.trim(),
        avatarUrl: finalAvatarUrl,
      );

      if (mounted) {
        setState(() {
          _avatarUrl = finalAvatarUrl;
          _selectedFileBytes = null;
          _selectedFileExt = null;
        });
        _showSnackBar("Profil berhasil diperbarui!", isError: false);
      }
    } catch (e) {
      _showSnackBar("Gagal menyimpan: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialog konfirmasi logout dan bersihkan data lokal.
  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Konfirmasi Keluar",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: const Text(
            "Apakah Anda yakin ingin keluar dari akun?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("BATAL", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  Navigator.pop(dialogContext);

                  _accelSubscription?.cancel();

                  // 1. Putuskan sesi cloud dari Supabase
                  await _apiService.signOut();

                  // 2. Bersihkan penyimpanan aman lokal
                  await _secureStorage.delete(key: "saved_email");
                  await _secureStorage.delete(key: "saved_password");

                  // 3. Arahkan kembali ke halaman login
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                } catch (e) {
                  if (mounted) _showSnackBar("Gagal logout: $e", isError: true);
                }
              },
              child: const Text(
                "KELUAR",
                style: TextStyle(color: errorRed, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Tampilkan pesan notifikasi (snackbar) ke user.
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? errorRed : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // UI utama halaman profil.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "PENGATURAN PROFIL",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAvatarPreview(),
                  const SizedBox(height: 12),
                  Text(
                    "Goncang ponsel untuk hapus foto",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    "NAMA LENGKAP",
                    _nameController,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "ALAMAT EMAIL",
                    _emailController,
                    Icons.email_outlined,
                    isReadOnly: true,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "DESKRIPSI",
                    _deskripsiController,
                    Icons.description_outlined,
                    isMultiLine: true,
                  ),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // Avatar preview dengan opsi upload/ubah foto.
  Widget _buildAvatarPreview() {
    ImageProvider? imageProvider;
    if (_selectedFileBytes != null) {
      imageProvider = MemoryImage(_selectedFileBytes!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_avatarUrl!);
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryGold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: primaryGold.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: surfaceDark,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white24)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourcePicker,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: bgDark, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Field input teks dengan label dan icon.
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    bool isMultiLine = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          maxLines: isMultiLine ? 4 : 1,
          minLines: 1,
          style: TextStyle(
            color: isReadOnly ? Colors.white38 : Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: surfaceDark,
            prefixIcon: Icon(icon, color: primaryGold, size: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGold, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Tombol simpan perubahan profil.
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          elevation: 4,
          shadowColor: primaryGold.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "SIMPAN PERUBAHAN",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  // Tombol logout dari akun.
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: _confirmLogout,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              size: 18,
              color: errorRed.withOpacity(0.8),
            ),
            const SizedBox(width: 10),
            const Text(
              "KELUAR DARI AKUN",
              style: TextStyle(
                color: errorRed,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
