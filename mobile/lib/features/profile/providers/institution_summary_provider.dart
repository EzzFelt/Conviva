import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../models/institution_summary.dart';

final institutionSummaryProvider =
    FutureProvider.family<InstitutionSummary, String>((ref, institutionId) async {
  final document = await AuthService.instance.getInstitutionById(institutionId);
  return InstitutionSummary.fromMap(
    id: document.id,
    data: document.data()!,
  );
});