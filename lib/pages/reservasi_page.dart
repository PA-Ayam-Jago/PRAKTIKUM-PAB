import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/reservation_model.dart';
import '../services/supabase_service.dart';
import 'package:flutter/services.dart';

// Halaman reservasi: menampilkan daftar jadwal studio dan form reservasi.
class ReservasiPage extends StatefulWidget {
  const ReservasiPage({super.key});

  @override
  State<ReservasiPage> createState() => _ReservasiPageState();
}

// State halaman reservasi: menangani input user, validasi, dan interaksi Supabase.
class _ReservasiPageState extends State<ReservasiPage> {
  final supabase = Supabase.instance.client;
  final _apiService = SupabaseService();

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _mulaiController = TextEditingController();
  final _selesaiController = TextEditingController();
  final _deskripsiController = TextEditingController();

  final _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isAscending = false;
  bool _filterOnlyMe = false;

  bool _isProcessing = false;
  int _refreshCounter = 0;

  // --------------------
  // State internal halaman
  // --------------------

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color bgDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF161616);
  static const Color errorRed = Color(0xFFE57373);

  @override
  void dispose() {
    _namaController.dispose();
    _phoneController.dispose();
    _tanggalController.dispose();
    _mulaiController.dispose();
    _selesaiController.dispose();
    _deskripsiController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Menampilkan notifikasi kecil di bagian atas layar.
  void _showTopNotification(
    BuildContext context,
    String message,
    bool isSuccess,
  ) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 50,
        right: 50,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSuccess
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  // Menentukan label penggunaan aktif/sudah selesai untuk reservasi approve.
  Widget _buildUsageStatus(
    String tanggal,
    String mulai,
    String selesai,
    String status,
  ) {
    if (status != 'approved') return const SizedBox.shrink();

    final now = DateTime.now();
    final startDT = DateTime.parse("$tanggal $mulai:00");
    final endDT = DateTime.parse("$tanggal $selesai:00");

    String label;
    Color color;

    if (now.isBefore(startDT)) {
      label = "BELUM DIPAKAI";
      color = Colors.blueAccent;
    } else if (now.isAfter(startDT) && now.isBefore(endDT)) {
      label = "SEDANG DIGUNAKAN";
      color = Colors.orangeAccent;
    } else {
      label = "SUDAH SELESAI";
      color = Colors.white24;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // Cek apakah jadwal baru bertabrakan dengan reservasi approved lain.
  Future<bool> _isTimeSlotOverlap(
    String tanggal,
    String mulai,
    String selesai,
    String? currentId,
  ) async {
    final response = await supabase
        .from('reservations')
        .select()
        .eq('tanggal', tanggal)
        .eq('status', 'approved');
    for (var row in response) {
      if (currentId != null && row['id'].toString() == currentId) continue;
      double toDouble(String time) {
        final parts = time.split(':');
        return double.parse(parts[0]) + (double.parse(parts[1]) / 60);
      }

      double startNew = toDouble(mulai);
      double endNew = toDouble(selesai);
      double startOld = toDouble(row['jam_mulai']);
      double endOld = toDouble(row['jam_selesai']);
      if (startNew < endOld && endNew > startOld) return true;
    }
    return false;
  }

  // Cek apakah user sudah punya reservasi pada tanggal yang sama.
  Future<bool> _hasExistingReservationToday(
    String userId,
    String tanggal,
    String? currentId,
  ) async {
    final response = await supabase
        .from('reservations')
        .select()
        .eq('user_id', userId)
        .eq('tanggal', tanggal)
        .neq('status', 'rejected');

    if (response.isEmpty) return false;

    // Jika sedang edit, pastikan tidak menghitung dirinya sendiri
    if (currentId != null) {
      final otherReservations = response
          .where((res) => res['id'].toString() != currentId)
          .toList();
      return otherReservations.isNotEmpty;
    }

    return true;
  }

  // Simpan data reservasi baru atau update reservasi existing.
  Future<void> _simpanReservasi({
    String? editId,
    required String userId,
    required BuildContext modalCtx,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final startParts = _mulaiController.text.split(':');
    final endParts = _selesaiController.text.split(':');

    final startHour = int.parse(startParts[0]);
    final endHour = int.parse(endParts[0]);

    final startMinutes = startHour * 60 + int.parse(startParts[1]);
    final endMinutes = endHour * 60 + int.parse(endParts[1]);

    if (startHour < 8 ||
        (endHour >= 17 && int.parse(endParts[1]) > 0) ||
        endHour > 17) {
      _showTopNotification(
        context,
        "Di luar jam operasional (08:00 - 17:00)",
        false,
      );
      return;
    }

    if (endMinutes <= startMinutes) {
      _showTopNotification(
        context,
        "Jam selesai harus setelah jam mulai",
        false,
      );
      return;
    }

    if ((endMinutes - startMinutes) < 60) {
      _showTopNotification(
        context,
        "Durasi minimal peminjaman adalah 1 jam",
        false,
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Validasi 1 Kali Sehari
      bool alreadyReserved = await _hasExistingReservationToday(
        userId,
        _tanggalController.text,
        editId,
      );
      if (alreadyReserved) {
        _showTopNotification(
          context,
          "Batas reservasi hanya 1 kali per hari",
          false,
        );
        return;
      }

      bool isOverlap = await _isTimeSlotOverlap(
        _tanggalController.text,
        _mulaiController.text,
        _selesaiController.text,
        editId,
      );
      if (isOverlap) {
        _showTopNotification(context, "Jadwal sudah terisi (Approved)", false);
        return;
      }

      final res = Reservation(
        id: editId ?? "",
        fullName: _namaController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        tanggal: _tanggalController.text.trim(),
        jamMulai: _mulaiController.text.trim(),
        jamSelesai: _selesaiController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        status: 'pending',
      );

      if (editId == null) {
        await _apiService.createReservation(res);
      } else {
        final updateData = res.toJson();
        updateData['user_id'] = userId;
        await supabase.from('reservations').update(updateData).eq('id', editId);
      }

      // --- PERBAIKAN DI SINI ---
      if (mounted) {
        // 1. Tutup bottom sheet terlebih dahulu
        Navigator.pop(modalCtx);

        // 2. Langsung set filter ke "RESERVASI SAYA" secara bersih tanpa microtask delay
        setState(() {
          _filterOnlyMe = true;
          _searchQuery =
              ""; // Opsional: bersihkan search query agar data pasti muncul
        });

        // 3. Tampilkan notifikasi sukses
        _showTopNotification(
          context,
          "Berhasil dikirim, menunggu persetujuan",
          true,
        );
      }
    } catch (e) {
      _showTopNotification(context, "Gagal: $e", false);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // UI utama halaman reservasi.
  @override
  Widget build(BuildContext context) {
    final String? uid = supabase.auth.currentUser?.id;
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "JADWAL STUDIO",
          style: TextStyle(
            color: primaryGold,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGold,
        onPressed: () => uid != null ? _showForm(userId: uid) : null,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
      ),
      body: Column(
        children: [
          _buildSearchArea(),
          _buildInfoBox(),
          Expanded(
            child: uid == null
                ? const Center(
                    child: CircularProgressIndicator(color: primaryGold),
                  )
                : _buildList(uid),
          ),
        ],
      ),
    );
  }

  // Bagian pencarian dan filter reservasi.
  Widget _buildSearchArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Cari jadwal atau tanggal (YYYY-MM-DD)...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: primaryGold,
                size: 22,
              ),
              filled: true,
              fillColor: surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(
                  "TERBARU",
                  !_isAscending && !_filterOnlyMe,
                  () => setState(() {
                    _isAscending = false;
                    _filterOnlyMe = false;
                  }),
                ),
                const SizedBox(width: 8),
                _chip(
                  "TERLAMA",
                  _isAscending && !_filterOnlyMe,
                  () => setState(() {
                    _isAscending = true;
                    _filterOnlyMe = false;
                  }),
                ),
                const SizedBox(width: 8),
                _chip(
                  "RESERVASI SAYA",
                  _filterOnlyMe,
                  () => setState(() {
                    _filterOnlyMe = true;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryGold : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // Kotak informasi jam operasional studio.
  Widget _buildInfoBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryGold.withOpacity(0.1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: primaryGold, size: 18),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "JAM OPERASIONAL",
                  style: TextStyle(
                    color: primaryGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "08.00 - 17.00 WITA",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Daftar reservasi yang diambil realtime dari Supabase.
  List<Map<String, dynamic>> _dedupeReservations(List<Map<String, dynamic>> items) {
    final unique = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (!unique.containsKey(id)) {
        unique[id] = item;
      }
    }
    return unique.values.toList();
  }

  Widget _buildList(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('reservations')
          .stream(primaryKey: ['id'])
          .order('tanggal', ascending: _isAscending),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: primaryGold),
          );

        final list = _dedupeReservations(snapshot.data!).where((i) {
          final query = _searchQuery.toLowerCase();
          final deskripsi = (i['deskripsi'] ?? "").toString().toLowerCase();
          final fullName = (i['full_name'] ?? "").toString().toLowerCase();
          final tanggalRaw = (i['tanggal'] ?? "").toString();

          String tanggalFormatted = "";
          try {
            final dateObj = DateTime.parse(tanggalRaw);
            tanggalFormatted = DateFormat(
              'EEEE, dd MMMM yyyy',
            ).format(dateObj).toLowerCase();
          } catch (_) {}

          final matchesSearch =
              deskripsi.contains(query) ||
              fullName.contains(query) ||
              tanggalRaw.contains(query) ||
              tanggalFormatted.contains(query);

          if (_filterOnlyMe) {
            return matchesSearch &&
                i['user_id'].toString().trim() == uid.trim();
          } else {
            return matchesSearch && i['status'] == 'approved';
          }
        }).toList();

        if (list.isEmpty)
          return Center(
            child: Text(
              "Jadwal tidak ditemukan",
              style: TextStyle(color: Colors.white.withOpacity(0.2)),
            ),
          );
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
          itemCount: list.length,
          itemBuilder: (context, index) => _buildCard(list[index], uid),
        );
      },
    );
  }

  // Kartu tampilan satu reservasi dalam daftar.
  Widget _buildCard(Map<String, dynamic> i, String uid) {
    bool isMe = i['user_id'].toString().trim() == uid.trim();
    String stat = i['status'] ?? 'pending';
    Color c = stat == 'approved'
        ? Colors.greenAccent
        : (stat == 'rejected' ? Colors.redAccent : Colors.orangeAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isMe
              ? primaryGold.withOpacity(0.4)
              : Colors.white.withOpacity(0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, dd MMM').format(DateTime.parse(i['tanggal'])),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stat.toUpperCase(),
                      style: TextStyle(
                        color: c,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildUsageStatus(
                    i['tanggal'],
                    i['jam_mulai'],
                    i['jam_selesai'],
                    stat,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${i['jam_mulai']} - ${i['jam_selesai']}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            i['deskripsi'] ?? "",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: isMe ? primaryGold : Colors.white10,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMe ? "Reservasi Anda" : (i['full_name'] ?? "User"),
                  style: TextStyle(
                    color: isMe ? primaryGold : Colors.white24,
                    fontSize: 13,
                  ),
                ),
              ),
              if (isMe && stat == 'pending') ...[
                IconButton(
                  onPressed: () => _showForm(item: i, userId: uid),
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white38,
                  ),
                ),
                IconButton(
                  onPressed: () => _konfirmasiHapus(i['id'].toString()),
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Dialog konfirmasi sebelum menghapus reservasi.
  void _konfirmasiHapus(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Hapus Jadwal?",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          "Tindakan ini tidak dapat dibatalkan.",
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("BATAL", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await supabase.from('reservations').delete().eq('id', id);

                if (mounted) Navigator.pop(ctx);

                if (mounted) {
                  setState(() {
                    setState(() => _refreshCounter++);
                  });
                }

                _showTopNotification(context, "Jadwal berhasil dihapus", true);
              } catch (e) {
                if (mounted) Navigator.pop(ctx);
                _showTopNotification(
                  context,
                  "Gagal menghapus jadwal: $e",
                  false,
                );
              }
            },
            child: const Text(
              "HAPUS",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modal form untuk tambah atau edit reservasi.
  void _showForm({Map<String, dynamic>? item, required String userId}) {
    if (item != null) {
      _namaController.text = item['full_name'] ?? '';
      _phoneController.text = item['phone_number'] ?? '';
      _tanggalController.text = item['tanggal'];
      _mulaiController.text = item['jam_mulai'];
      _selesaiController.text = item['jam_selesai'];
      _deskripsiController.text = item['deskripsi'] ?? '';
    } else {
      _namaController.clear();
      _phoneController.clear();
      _tanggalController.clear();
      _mulaiController.clear();
      _selesaiController.clear();
      _deskripsiController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setST) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            left: 24,
            right: 24,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Buat Jadwal Baru",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Lengkapi data untuk memesan studio",
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildInputLabel("NAMA LENGKAP"),
                  _buildRegisterStyleField(
                    _namaController,
                    Icons.person_outline,
                    "Contoh: Budi Santoso",
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    validator: (v) {
                      final trimmed = v?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return "Nama tidak boleh kosong";
                      }
                      if (trimmed.length < 3) {
                        return "Nama terlalu pendek";
                      }
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
                        return "Nama hanya boleh berisi huruf";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel("NOMOR WHATSAPP"),
                  _buildRegisterStyleField(
                    _phoneController,
                    Icons.phone_iphone_rounded,
                    "Contoh: 08123456789",
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(13),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Nomor WA tidak boleh kosong";
                      }
                      if (!RegExp(r'^(08|628)[0-9]{8,11}$').hasMatch(v)) {
                        return "Format nomor tidak valid";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel("TANGGAL PINJAM"),
                  _buildRegisterStyleField(
                    _tanggalController,
                    Icons.calendar_month_outlined,
                    "Pilih Tanggal",
                    readOnly: true,
                    onTap: () async {
                      DateTime? d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: primaryGold,
                              onPrimary: Colors.black,
                              surface: surfaceDark,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (d != null)
                        setST(
                          () => _tanggalController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(d),
                        );
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? "Tanggal wajib dipilih" : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel("MULAI"),
                            _buildRegisterStyleField(
                              _mulaiController,
                              Icons.access_time_rounded,
                              "08:00",
                              readOnly: true,
                              onTap: () async {
                                TimeOfDay? t = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 8,
                                    minute: 0,
                                  ),
                                );
                                if (t != null)
                                  setST(
                                    () => _mulaiController.text =
                                        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                                  );
                              },
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Mulai?" : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel("SELESAI"),
                            _buildRegisterStyleField(
                              _selesaiController,
                              Icons.update_rounded,
                              "10:00",
                              readOnly: true,
                              onTap: () async {
                                TimeOfDay? t = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 10,
                                    minute: 0,
                                  ),
                                );
                                if (t != null)
                                  setST(
                                    () => _selesaiController.text =
                                        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                                  );
                              },
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Selesai?" : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel("KETERANGAN KEPERLUAN"),
                  _buildRegisterStyleField(
                    _deskripsiController,
                    Icons.notes_rounded,
                    "Contoh: Latihan Band Persiapan Dies Natalis",
                    isLong: true,
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return "Keterangan tidak boleh kosong";
                      if (v.length < 10)
                        return "Berikan detail minimal 10 karakter";
                      return null;
                    },
                  ),
                  const SizedBox(height: 19),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _simpanReservasi(
                              editId: item?['id']?.toString(),
                              userId: userId,
                              modalCtx: modalCtx,
                            ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              "DAFTAR JADWAL",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(modalCtx),
                      child: RichText(
                        text: const TextSpan(
                          text: "ingin membatalkan? ",
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                          children: [
                            TextSpan(
                              text: "Kembali",
                              style: TextStyle(
                                color: primaryGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Label kecil untuk setiap field input.
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: primaryGold,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // Field input dengan styling khusus untuk form reservasi.
  Widget _buildRegisterStyleField(
    TextEditingController c,
    IconData icon,
    String hint, {
    VoidCallback? onTap,
    bool isLong = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: c,
      inputFormatters: inputFormatters,
      onTap: onTap,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: isLong ? 3 : 1,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white60, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        errorStyle: const TextStyle(color: errorRed, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),
    );
  }
}
