import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';

class ReportEmergencyIllustration extends StatelessWidget {
  const ReportEmergencyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    return Semantics(
      image: true,
      label: 'Ilustração de uma ligação de emergência',
      child: SizedBox(
        height: sizes.xxl * 4.2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: sizes.lg,
              child: Transform.rotate(
                angle: -0.18,
                child: Container(
                  width: sizes.xxl * 2.2,
                  height: sizes.xxl * 3.6,
                  padding: EdgeInsets.all(sizes.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(sizes.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: .24),
                        blurRadius: sizes.md,
                        offset: Offset(0, sizes.sm),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: sizes.md),
                      Text(
                        '911',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontSize: 34,
                            ),
                      ),
                      Text(
                        'EMERGENCY\nCALL',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.call_end_rounded,
                        color: colorScheme.onPrimary,
                        size: sizes.xl,
                      ),
                      SizedBox(height: sizes.md),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: sizes.md,
              bottom: 0,
              child: Image.asset(
                AssetPaths.elderAvatar,
                height: sizes.xxl * 3.4,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
