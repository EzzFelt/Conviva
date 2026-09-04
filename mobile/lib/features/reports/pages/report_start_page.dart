import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/constants/assets_paths.dart';
import '../models/report_draft.dart';
import '../widgets/report_flow_scaffold.dart';

class ReportStartPage extends ConsumerWidget {
  const ReportStartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizes = context.appSizes;

    return ReportFlowScaffold(
      step: 1,
      showProgress: false,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                text: 'Bem vindo a ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                children: const [
                  TextSpan(
                    text: 'Central de\nDenúncias!',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF7A1A),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: sizes.xl, bottom: sizes.md),
                  child: Image.asset(
                    AssetPaths.reportEmergency,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: sizes.md),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A1A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 52),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () {
                  ref.read(reportDraftProvider.notifier).reset();
                  context.go(RouteNames.reportType);
                },
                child: const Text('Continuar'),
              ),
            ),
            SizedBox(height: sizes.lg),
          ],
        ),
      ),
    );
  }
}
