import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reservation_model.dart';
import '../models/user_model.dart';

// Layanan wrapper Supabase untuk auth, profil, storage, dan reservasi.
class SupabaseService {
  final _supabase = Supabase.instance.client;

  SupabaseClient get client => _supabase;

  User? get currentUser => _supabase.auth.currentUser;

  // ================= AUTHENTICATION =================

  // SIGN IN
  // Masuk dengan email dan password menggunakan Supabase Auth.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      throw "Terjadi kesalahan yang tidak terduga: $e";
    }
  }

  // SIGN UP
  // Buat akun baru dan simpan profil awal di tabel profiles.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'phone': phone},
      );

      final user = res.user;

      if (user != null) {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'name': name,
          'phone': phone,
          'role': 'mahasiswa',
          'email': email,
        });
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw "Registrasi gagal: $e";
    }
  }

  // LOGOUT
  // Keluar dari sesi Supabase saat ini.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ================= PROFILE & USER DATA =================

  // GET USER MODEL (Full object)
  // Ambil data profil pengguna lengkap berdasarkan ID.
  Future<UserModel?> getUserModel(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) return UserModel.fromJson(data);
      return null;
    } catch (e) {
      debugPrint("Error fetching user model: $e");
      return null;
    }
  }

  // GET CURRENT PROFILE (Sering digunakan di Homepage/Login)
  // Ambil informasi profil saat ini termasuk role dan avatar.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await _supabase
          .from('profiles')
          .select(
            'role, name, avatar_url',
          ) // Memastikan avatar_url ikut terpanggil
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      debugPrint("Error getting current profile: $e");
      return null;
    }
  }

  // UPDATE PROFILE
  // Memperbarui nama, telepon, dan avatar di tabel profiles.
  Future<void> updateUserProfile({
    required String name,
    required String phone,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('profiles')
          .update({'name': name, 'phone': phone, 'avatar_url': avatarUrl})
          .eq('id', user.id);

      // Sinkronisasi data ke Auth Supabase Metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': name}),
      );
    } catch (e) {
      throw "Gagal update profil: $e";
    }
  }

  // UPLOAD AVATAR TO STORAGE
  // Simpan avatar di storage Supabase dan kembalikan public URL.
  Future<String?> uploadAvatar({
    required Uint8List fileBytes,
    required String extension,
  }) async {
    final user = currentUser;
    if (user == null) return null;
    try {
      // Gunakan nama file yang unik berdasarkan timestamp
      final String fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String path = '${user.id}/$fileName';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true, // Menimpa file jika path sama
              contentType: 'image/$extension',
            ),
          );

      // Mengambil URL publik untuk disimpan ke database profiles
      return _supabase.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      throw "Gagal upload gambar: $e";
    }
  }

  // ================= RESERVATIONS =================

  // CREATE RESERVATION
  // Simpan reservasi baru ke tabel reservations.
  Future<void> createReservation(Reservation reservation) async {
    final user = currentUser;
    if (user == null) throw "Sesi berakhir, silakan login kembali";

    try {
      final Map<String, dynamic> data = reservation.toJson();
      data['user_id'] = user.id;

      await _supabase.from('reservations').insert(data);
    } catch (e) {
      debugPrint("Error creating reservation: $e");
      throw "Gagal menyimpan reservasi: $e";
    }
  }

  // STREAM RESERVATION (Realtime)
  // Stream data reservasi agar UI dapat update otomatis.
  Stream<List<Reservation>> getReservationStream() {
    return _supabase
        .from('reservations')
        .stream(primaryKey: ['id'])
        .order('tanggal', ascending: false)
        .map((data) => data.map((json) => Reservation.fromJson(json)).toList());
  }

  // UPDATE STATUS RESERVASI
  // Ubah status reservasi seperti pending/approved/rejected.
  Future<void> updateReservationStatus(String id, String status) async {
    try {
      await _supabase
          .from('reservations')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      throw "Gagal update status: $e";
    }
  }

  // GET ALL RESERVATIONS (Future)
  // Ambil semua reservasi untuk tampilan daftar riwayat.
  Future<List<Reservation>> getAllReservations() async {
    try {
      final response = await _supabase
          .from('reservations')
          .select()
          .order('tanggal', ascending: false);

      return (response as List)
          .map((json) => Reservation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Error fetching all reservations: $e");
      return [];
    }
  }

  // ================= STATISTICS =================

  // HITUNG TOTAL RESERVASI BULAN INI
  Future<int> getTotalReservasiBulanIni() async {
    try {
      final now = DateTime.now();
      final firstDayMonth = DateTime(now.year, now.month, 1).toIso8601String();

      final response = await _supabase
          .from('reservations')
          .select('id')
          .gte('tanggal', firstDayMonth);

      return (response as List).length;
    } catch (e) {
      debugPrint("Error fetching monthly stats: $e");
      return 0;
    }
  }
}
