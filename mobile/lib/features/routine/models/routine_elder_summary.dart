import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class RoutineElderSummary {
  const RoutineElderSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.institutionId,
    this.photoUrl,
    this.gender,
    this.bloodType,
    this.dependencyLevel,
  });

  final String id;
  final String name;
  final String phone;
  final String institutionId;
  final String? photoUrl;
  final String? gender;
  final String? bloodType;
  final String? dependencyLevel;

  factory RoutineElderSummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null || data['type']?.toString() != 'idoso') {
      throw StateError('O usuário ${document.id} não é um idoso válido.');
    }

    return RoutineElderSummary(
      id: document.id,
      name: data['name']?.toString().trim() ?? 'Idoso',
      phone: data['phone']?.toString().trim() ?? '',
      institutionId: data['institutionId']?.toString().trim() ?? '',
      photoUrl: _optionalString(data['photoUrl']),
      gender: _optionalString(data['gender'] ?? data['sex']),
      bloodType: _optionalString(data['bloodType']),
      dependencyLevel: _optionalString(data['dependencyLevel']),
    );
  }

  static String? _optionalString(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
