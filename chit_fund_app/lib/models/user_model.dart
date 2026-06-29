import 'package:uuid/uuid.dart';

class AppUser {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final String? mobile;
  final String role;       // owner / agent / member
  final String status;     // pending / approved / rejected
  final String? requestedGroupId;
  final String createdAt;

  AppUser({
    String? id,
    required this.username,
    required this.password,
    required this.fullName,
    this.mobile,
    required this.role,
    this.status = 'pending',
    this.requestedGroupId,
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      username: map['username'],
      password: map['password'] ?? '',
      fullName: map['full_name'],
      mobile: map['mobile'],
      role: map['role'],
      status: map['status'] ?? 'pending',
      requestedGroupId: map['requested_group_id'],
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'mobile': mobile,
      'role': role,
      'status': status,
      'requested_group_id': requestedGroupId,
      'created_at': createdAt,
    };
  }
}