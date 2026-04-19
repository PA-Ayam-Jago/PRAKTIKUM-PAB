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
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['full_name'] ?? 'User',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'mahasiswa',
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
}
