import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

import '../../../shared/widgets/button_widget.dart';

import '../models/onboarding_item.dart';
import 'indicator_widget.dart';

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.pageIndex,
    required this.indicatorCount,
    required this.item,
    required this.isLastOnboarding,
    required this.onContinue,
    required this.onLogin,
  });

  final int pageIndex;
  final int indicatorCount;
  final OnboardingItem item;
  final bool isLastOnboarding;
  final VoidCallback onContinue;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradientColors = context.appGradientColors;
    final sizes = context.appSizes;
    final foregroundColor = colorScheme.onPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors.top,
            gradientColors.bottom,
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;
            final illustrationSize = (w * .72)
                .clamp(0.0, h * .44)
                .toDouble();

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: h * .52,
                        width: w,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: sizes.lg,
                              child: Container(
                                width: illustrationSize,
                                height: illustrationSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color.lerp(
                                    gradientColors.top,
                                    colorScheme.onSurface,
                                    .14,
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              child: Image.asset(
                                item.image,
                                width: illustrationSize,
                                height: illustrationSize,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: sizes.md,
                        ),
                        child: OnboardingIndicator(
                          currentIndex: pageIndex,
                          itemCount: indicatorCount,
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: sizes.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  if (item.subtitleNormal.isNotEmpty)
                                    TextSpan(
                                      text: item.subtitleNormal,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: foregroundColor,
                                          ),
                                    ),

                                  TextSpan(
                                    text: item.subtitleBold,
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(
                                          color: foregroundColor,
                                        ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),

                            if (item.body.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: sizes.sm),
                                child: Text(
                                  item.body,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: foregroundColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      if (!isLastOnboarding)
                        Padding(
                          padding: EdgeInsets.only(
                            left: sizes.lg,
                            right: sizes.lg,
                            bottom: sizes.lg,
                          ),
                          child: ButtonWidget(
                            size: ButtonSize.large,
                            variant: ButtonVariant.surface,
                            onPressed: onContinue,
                          ),
                        )
                      else ...[
                        Padding(
                          padding: EdgeInsets.only(
                            left: sizes.lg,
                            right: sizes.lg,
                            bottom: sizes.sm,
                          ),
                          child: ButtonWidget(
                            label: 'Comece Agora!',
                            size: ButtonSize.large,
                            variant: ButtonVariant.surface,
                            onPressed: onContinue,
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.only(bottom: sizes.md),
                          child: TextButton(
                            onPressed: onLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: foregroundColor,
                              minimumSize: Size(0, sizes.buttonSmall),
                              padding: EdgeInsets.symmetric(
                                horizontal: sizes.sm,
                              ),
                            ),
                            child: Text.rich(
                              TextSpan(
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: foregroundColor,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Já tem uma conta? ',
                                  ),
                                  TextSpan(
                                    text: 'Entre',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: foregroundColor,
                                          decoration:
                                              TextDecoration.underline,
                                          decorationColor: foregroundColor,
                                        ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
