import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import 'report_progress_bar.dart';

class ReportFlowScaffold extends StatelessWidget {
  const ReportFlowScaffold({
    super.key,
    required this.step,
    required this.body,
    this.bottomButton,
    this.useGradient = false,
    this.showProgress = true,
    this.backColor,
  });

  static const totalSteps = 7;

  final int step;
  final Widget body;
  final Widget? bottomButton;
  final bool useGradient;
  final bool showProgress;
  final Color? backColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final gradient = [colorScheme.surface, colorScheme.primaryContainer];
    final iconColor = backColor ?? colorScheme.primary;

    return Scaffold(
      backgroundColor: useGradient ? null : colorScheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: useGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradient[1], gradient[0]],
                )
              : null,
          color: useGradient ? null : colorScheme.surface,
        ),
        child: SafeArea(
          bottom: true,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sizes.md,
                  sizes.sm,
                  sizes.lg,
                  sizes.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Voltar',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.elderHome);
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: iconColor,
                      size: sizes.lg,
                    ),
                  ),
                ),
              ),
              if (showProgress)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizes.lg),
                  child: ReportProgressBar(step: step, totalSteps: totalSteps),
                ),
              Expanded(child: body),
              if (bottomButton != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.sm,
                    sizes.lg,
                    sizes.md,
                  ),
                  child: bottomButton,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
