import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps to `wards/{wardId}` (PRD §10).
class WardModel {
  final String wardId;
  final String wardName;
  final String floor;
  final String description;
  final bool active;
  final DateTime? createdAt;

  WardModel({
    required this.wardId,
    required this.wardName,
    required this.floor,
    required this.description,
    required this.active,
    this.createdAt,
  });

  factory WardModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return WardModel(
      wardId: doc.id,
      wardName: (data['wardName'] as String?) ?? '',
      floor: (data['floor'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      active: (data['active'] as bool?) ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'wardId': wardId,
      'wardName': wardName,
      'floor': floor,
      'description': description,
      'active': active,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
