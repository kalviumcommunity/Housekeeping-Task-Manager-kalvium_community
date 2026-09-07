import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';

/// Maps to `users/{uid}` (PRD §6, §9).
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String employeeId;
  final UserRole role;
  final String assignedWard;
  final bool active;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.role,
    required this.assignedWard,
    required this.active,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      uid: doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      employeeId: (data['employeeId'] as String?) ?? '',
      role: UserRole.fromValue(data['role'] as String?),
      assignedWard: (data['assignedWard'] as String?) ?? '',
      active: (data['active'] as bool?) ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'employeeId': employeeId,
      'role': role.value,
      'assignedWard': assignedWard,
      'active': active,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? assignedWard,
    bool? active,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      employeeId: employeeId,
      role: role,
      assignedWard: assignedWard ?? this.assignedWard,
      active: active ?? this.active,
      createdAt: createdAt,
    );
  }
}
