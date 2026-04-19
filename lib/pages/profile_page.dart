import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseService _apiService = SupabaseService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = true;
  String? _avatarUrl;
  Uint8List? _selectedFileBytes;
  String? _selectedFileExt;

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color bgDark = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color errorRed = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deskripsiController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _apiService.currentUser;
      if (user == null) return;

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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    final Uint8List bytes = await image.readAsBytes();
    final String extension = image.name.split('.').last.toLowerCase();

    setState(() {
      _selectedFileBytes = bytes;
      _selectedFileExt = extension;
    });
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar("Nama tidak boleh kosong", isError: true);
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
        });
        _showSnackBar("Profil berhasil diperbarui!", isError: false);
      }
    } catch (e) {
      _showSnackBar("Gagal menyimpan: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

                  await _apiService.signOut();

                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                } catch (e) {
                  if (mounted) {
                    _showSnackBar("Gagal logout: $e", isError: true);
                  }
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

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? errorRed : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                  const SizedBox(height: 40),
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
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: primaryGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
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
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGold),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          "SIMPAN PERUBAHAN",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _confirmLogout,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 18, color: errorRed),
            SizedBox(width: 8),
            Text("KELUAR DARI AKUN", style: TextStyle(color: errorRed)),
          ],
        ),
      ),
    );
  }
}
