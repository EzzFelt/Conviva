import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';
import '../widgets/report_flow_scaffold.dart';

class ReportSuccessPage extends StatelessWidget {
  const ReportSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    return ReportFlowScaffold(
      step: ReportFlowScaffold.totalSteps,
      showProgress: false,
      showNavigationBar: false,
      body: Padding(
        padding: EdgeInsets.all(sizes.lg),
        child: Column(
          children: [
            SizedBox(height: sizes.xxl),
            Text('Sua denúncia foi finalizada com sucesso!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: sizes.xxl),
            Expanded(
              child: Center(
                child: Image.asset(
                  AssetPaths.reportSuccess,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.elderHome),
              child: const Text('Voltar para o início'),
            ),
            SizedBox(height: sizes.xl),
          ],
        ),
      ),
    );
  }
}
