import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/reservation_model.dart';
import '../services/supabase_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final SupabaseService _apiService = SupabaseService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Reservation>> _events = {};

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color bgDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF161616);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _groupEvents(List<Reservation> data) {
    _events = {};
    for (var item in data) {
      try {
        DateTime date = DateTime.parse(item.tanggal).toLocal();
        DateTime dayOnly = DateTime(date.year, date.month, date.day);

        if (_events[dayOnly] == null) _events[dayOnly] = [];
        _events[dayOnly]!.add(item);
      } catch (e) {
        debugPrint("Error parsing date: $e");
      }
    }
  }

  Future<void> _handleUpdateStatus(String id, String status) async {
    try {
      await _apiService.updateReservationStatus(id, status);
      if (mounted) {
        _showTopNotification(
          "Reservasi di-${status == 'approved' ? 'setujui' : 'tolak'}",
          status == 'approved',
        );
      }
    } catch (e) {
      _showTopNotification("Gagal memperbarui status", false);
    }
  }

  void _showTopNotification(String message, bool isSuccess) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: MediaQuery.of(context).size.width * 0.15,
        right: MediaQuery.of(context).size.width * 0.15,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSuccess
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.info_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
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
          "ADMIN MONITORING",
          style: TextStyle(
            color: primaryGold,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: _apiService.getReservationStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGold),
            );
          }

          final allData = snapshot.data ?? [];
          _groupEvents(allData);

          final filteredData = allData.where((item) {
            try {
              final resDate = DateTime.parse(item.tanggal);
              return isSameDay(resDate, _selectedDay);
            } catch (_) {
              return false;
            }
          }).toList();

          return Column(
            children: [
              _buildCalendar(),
              _buildInfoBox(),
              _buildSectionTitle(),
              Expanded(
                child: filteredData.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                        itemCount: filteredData.length,
                        itemBuilder: (context, i) =>
                            _buildAdminCard(filteredData[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Text(
            "DETAIL RESERVASI",
            style: TextStyle(
              color: primaryGold,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: 15),
          Expanded(child: Divider(color: Colors.white10)),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) =>
            _events[DateTime(day.year, day.month, day.day)] ?? [],
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        calendarStyle: const CalendarStyle(
          markerDecoration: BoxDecoration(
            color: primaryGold,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.white10,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: primaryGold,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.redAccent),
          outsideDaysVisible: false,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: primaryGold),
          rightChevronIcon: Icon(Icons.chevron_right, color: primaryGold),
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
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: primaryGold,
              size: 18,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TANGGAL DIPILIH",
                  style: TextStyle(
                    color: primaryGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(_selectedDay!),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(Reservation item) {
    final status = item.status.toLowerCase();
    Color statusColor = status == 'approved'
        ? Colors.greenAccent
        : (status == 'rejected' ? Colors.redAccent : Colors.orangeAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.fullName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildBadge(status, statusColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.phoneNumber,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: primaryGold),
              const SizedBox(width: 8),
              Text(
                "${item.jamMulai} - ${item.jamSelesai}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.deskripsi,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    "TOLAK",
                    Colors.redAccent,
                    () => _handleUpdateStatus(item.id, 'rejected'),
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionBtn(
                    "SETUJUI",
                    Colors.greenAccent,
                    () => _handleUpdateStatus(item.id, 'approved'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    Color color,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isOutlined
              ? BorderSide(color: color, width: 0.5)
              : BorderSide.none,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isOutlined ? color : Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: Colors.white.withOpacity(0.05),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            "Tidak ada jadwal untuk tanggal ini",
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
