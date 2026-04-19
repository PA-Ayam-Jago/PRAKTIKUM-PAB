class Reservation {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String deskripsi;
  final String status;

  Reservation({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.deskripsi,
    required this.status,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'].toString(),
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      tanggal: json['tanggal'] ?? '',
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      status: json['status'] ?? 'ditunda',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'tanggal': tanggal,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'deskripsi': deskripsi,
      'status': status,
    };
  }
}
