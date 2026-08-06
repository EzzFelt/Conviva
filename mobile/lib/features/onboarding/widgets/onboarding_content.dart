import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/route_names.dart';

import '../../../shared/widgets/button_widget.dart';

import '../../auth/models/auth_mode.dart';

import '../models/onboarding_arguments.dart';
import '../pages/onboarding_page.dart';
import '../models/onboarding_item.dart';
import 'indicator_widget.dart';

class OnboardingContent extends StatelessWidget {
  final int pageIndex;
  final OnboardingItem item;
  final bool isLastOnboarding;
  final VoidCallback onContinue;

  const OnboardingContent({
    super.key,
    required this.pageIndex,
    required this.item,
    required this.isLastOnboarding,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientTop,
            AppColors.gradientBottom,
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;

            return Column(
              children: [
                SizedBox(
                  height: h * .56,
                  width: w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: h * .04,
                        child: Container(
                          width: w * .72,
                          height: w * .72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE04500),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 0,
                        child: Image.asset(
                          item.image,
                          width: w * .72,
                          height: w * .72,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: h * .025,
                  ),
                  child: OnboardingIndicator(
                    currentIndex: pageIndex,
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * .09,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              height: 1.35,
                            ),
                            children: [
                              if (item.subtitleNormal.isNotEmpty)
                                TextSpan(
                                  text: item.subtitleNormal,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                              TextSpan(
                                text: item.subtitleBold,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (item.body.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: h * .012,
                            ),
                            child: Text(
                              item.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (!isLastOnboarding)
                  Padding(
                    padding: EdgeInsets.only(
                      left: w * .09,
                      right: w * .09,
                      bottom: h * .04,
                    ),
                    child: ButtonWidget(
                      size: ButtonSize.big,
                      variant: ButtonVariant.white,
                      onPressed: onContinue,
                    ),
                  )
                else ...[
                  Padding(
                    padding: EdgeInsets.only(
                      left: w * .09,
                      right: w * .09,
                      bottom: h * .02,
                    ),
                    child: ButtonWidget(
                      label: 'Comece Agora!',
                      size: ButtonSize.big,
                      variant: ButtonVariant.white,
                      onPressed: onContinue,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                      bottom: h * .04,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        context.go(
                          RouteNames.onboarding,
                          extra: const OnboardingArguments(
                            initialPage: OnboardingPages.accountType,
                            authMode: AuthMode.login,
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: 'Já tem uma conta? ',
                            ),
                            TextSpan(
                              text: 'Entre',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}