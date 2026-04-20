import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/reservation_model.dart';
import '../services/supabase_service.dart';

class ReservasiPage extends StatefulWidget {
  const ReservasiPage({super.key});

  @override
  State<ReservasiPage> createState() => _ReservasiPageState();
}

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

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color bgDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF161616);
  static const Color inputFill = Color(0xFF1E1E1E);

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

  Future<void> _simpanReservasi({
    String? editId,
    required String userId,
    required BuildContext modalCtx,
  }) async {
    if (!_formKey.currentState!.validate()) return;
    final startParts = _mulaiController.text.split(':');
    final endParts = _selesaiController.text.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    if (endMinutes <= startMinutes) {
      _showTopNotification(
        context,
        "Jam selesai harus setelah jam mulai",
        false,
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
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

      if (mounted) {
        Navigator.pop(modalCtx);
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

  Widget _buildList(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('reservations')
          .stream(primaryKey: ['id'])
          .order('tanggal', ascending: _isAscending),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: primaryGold),
          );
        }

        final list = snapshot.data!.where((i) {
          final query = _searchQuery.toLowerCase();

          // Logika Pencarian Diperluas: Cek Deskripsi, Nama, dan Tanggal
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

        if (list.isEmpty) {
          return Center(
            child: Text(
              "Jadwal tidak ditemukan",
              style: TextStyle(color: Colors.white.withOpacity(0.2)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
          itemCount: list.length,
          itemBuilder: (context, index) => _buildCard(list[index], uid),
        );
      },
    );
  }

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
              await supabase.from('reservations').delete().eq('id', id);
              if (mounted) Navigator.pop(ctx);
              _showTopNotification(context, "Jadwal berhasil dihapus", true);
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
                children: [
                  const Text(
                    "AJUKAN JADWAL",
                    style: TextStyle(
                      color: primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildValidatedField(
                    _namaController,
                    Icons.person,
                    "Nama Lengkap",
                    validator: (v) =>
                        v == null || v.isEmpty ? "Nama wajib diisi" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildValidatedField(
                    _phoneController,
                    Icons.phone,
                    "WhatsApp",
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.length < 10
                        ? "Nomor WA tidak valid"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildValidatedField(
                    _tanggalController,
                    Icons.calendar_today,
                    "Tanggal",
                    readOnly: true,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Pilih tanggal" : null,
                    onTap: () async {
                      DateTime? d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (d != null)
                        setST(
                          () => _tanggalController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(d),
                        );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildValidatedField(
                          _mulaiController,
                          Icons.timer,
                          "Mulai",
                          readOnly: true,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Mulai" : null,
                          onTap: () async {
                            TimeOfDay? t = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 8, minute: 0),
                            );
                            if (t != null)
                              setST(
                                () => _mulaiController.text =
                                    "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                              );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildValidatedField(
                          _selesaiController,
                          Icons.timer_off,
                          "Selesai",
                          readOnly: true,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Selesai" : null,
                          onTap: () async {
                            TimeOfDay? t = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 10, minute: 0),
                            );
                            if (t != null)
                              setST(
                                () => _selesaiController.text =
                                    "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                              );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildValidatedField(
                    _deskripsiController,
                    Icons.description,
                    "Keterangan",
                    isLong: true,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Berikan keterangan" : null,
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
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
                              "KONFIRMASI",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
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

  Widget _buildValidatedField(
    TextEditingController c,
    IconData i,
    String h, {
    VoidCallback? onTap,
    bool isLong = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: isLong ? 3 : 1,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: h,
        hintStyle: const TextStyle(color: Colors.white10),
        prefixIcon: Icon(i, color: primaryGold, size: 20),
        filled: true,
        fillColor: inputFill,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryGold, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}
