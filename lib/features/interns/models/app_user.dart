import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/enums.dart';

/// A document in the `users` collection (an admin or an intern).
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.phone = '',
    this.department = '',
    this.mentor = '',
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String phone;
  final String department;
  final String mentor;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == UserRole.admin;
  bool get isIntern => role == UserRole.intern;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromValue(map['role'] as String?),
      isActive: map['isActive'] as bool? ?? false,
      phone: map['phone'] as String? ?? '',
      department: map['department'] as String? ?? '',
      mentor: map['mentor'] as String? ?? '',
      startDate: _toDate(map['startDate']),
      endDate: _toDate(map['endDate']),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  /// Fields the app writes. `createdAt` / `updatedAt` are set by the
  /// repository with server timestamps, so they are not included here.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email.toLowerCase(),
      'role': role.value,
      'isActive': isActive,
      'phone': phone,
      'department': department,
      'mentor': mentor,
      'startDate': startDate == null ? null : Timestamp.fromDate(startDate!),
      'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
    };
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? department,
    String? mentor,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      mentor: mentor ?? this.mentor,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
