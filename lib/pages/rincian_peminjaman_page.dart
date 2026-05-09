import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/reservation_model.dart';

class RincianPeminjamanPage extends StatefulWidget {
  const RincianPeminjamanPage({super.key});

  @override
  State<RincianPeminjamanPage> createState() => _RincianPeminjamanPageState();
}

class _RincianPeminjamanPageState extends State<RincianPeminjamanPage> {
  final SupabaseService _apiService = SupabaseService();
  List<Reservation> allData = [];
  List<Reservation> filteredData = [];
  bool isLoading = true;

  String searchQuery = "";
  String selectedStatus = "Semua";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _apiService.getAllReservations();
      setState(() {
        allData = data;
        filteredData = data;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Error load data: $e");
    }
  }

  void _applyFilter() {
    setState(() {
      filteredData = allData.where((res) {
        final bool matchesText =
            res.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            res.tanggal.toLowerCase().contains(searchQuery.toLowerCase());

        final String currentResStatus = res.status.trim().toLowerCase();
        final String targetStatus = selectedStatus.trim().toLowerCase();

        final bool matchesStatus =
            selectedStatus == "Semua" || currentResStatus == targetStatus;

        return matchesText && matchesStatus;
      }).toList();
    });
  }

  String _getUsageStatus(String dateStr) {
    try {
      DateTime reservationDate = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      if (reservationDate.isBefore(today)) {
        return "SUDAH SELESAI";
      } else {
        return "BELUM DIPAKAI";
      }
    } catch (e) {
      return "BELUM DIPAKAI";
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGold = Color(0xFFD4AF37);
    const Color bgDark = Color(0xFF0A0A0A);
    const Color surfaceDark = Color(0xFF161616);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "RIWAYAT PEMINJAMAN",
          style: TextStyle(
            color: primaryGold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: TextField(
              onChanged: (val) {
                searchQuery = val;
                _applyFilter();
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Cari nama atau tanggal...",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: primaryGold),
                filled: true,
                fillColor: surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, bottom: 15),
              child: Row(
                children: ["SEMUA", "PENDING", "APPROVED", "REJECTED"].map((
                  status,
                ) {
                  final isSelected = selectedStatus.toUpperCase() == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedStatus = status == "SEMUA"
                                ? "Semua"
                                : status;
                            _applyFilter();
                          });
                        }
                      },
                      selectedColor: primaryGold,
                      backgroundColor: surfaceDark,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? primaryGold
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryGold),
                  )
                : filteredData.isEmpty
                ? Center(
                    child: Text(
                      "Data tidak ditemukan",
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      final usageStatus = _getUsageStatus(item.tanggal);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceDark,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildStatusBadge(item.status),
                                    const SizedBox(height: 5),
                                    _buildUsageBadge(usageStatus),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            Row(
                              children: [
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  item.tanggal,
                                ),
                                const SizedBox(width: 15),
                                _buildInfoRow(
                                  Icons.access_time_rounded,
                                  "13:00 - 15:00",
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            _buildInfoRow(
                              Icons.phone_android,
                              item.phoneNumber,
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              child: Divider(color: Colors.white10, height: 1),
                            ),

                            const Text(
                              "KETERANGAN:",
                              style: TextStyle(
                                color: primaryGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.deskripsi.isNotEmpty
                                  ? item.deskripsi
                                  : "Tidak ada keterangan.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37).withOpacity(0.7), size: 14),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUsageBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'disetujui':
      case 'approved':
        return Colors.greenAccent;
      case 'ditolak':
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
        return const Color(0xFFD4AF37);
      default:
        return Colors.grey;
    }
  }
}
