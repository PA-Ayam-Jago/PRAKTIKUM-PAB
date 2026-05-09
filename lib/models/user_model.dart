class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name'] ?? json['full_name'] ?? 'User',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'mahasiswa',
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }

  // Helper untuk pengecekan role yang lebih aman
  bool get isAdmin => role.toLowerCase() == 'admin';
}
