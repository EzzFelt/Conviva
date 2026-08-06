import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';

import '../../../shared/widgets/back_button_widget.dart';
import '../../../shared/widgets/border_card_widget.dart';

import '../../auth/models/account_type.dart';
import '../../auth/models/auth_arguments.dart';
import '../../auth/models/auth_mode.dart';

class AccountTypePage extends StatelessWidget {
  final VoidCallback onBack;
  final AuthMode authMode;

  const AccountTypePage({
    super.key,
    required this.onBack,
    required this.authMode,
  });

  void _navigate(
    BuildContext context,
    AccountType accountType,
  ) {
    final arguments = AuthArguments(
      accountType: accountType,
      authMode: authMode,
    );

    if (authMode == AuthMode.register) {
      context.go(
        RouteNames.register,
        extra: arguments,
      );
    } else {
      context.go(
        RouteNames.login,
        extra: arguments,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: w * .07,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * .03),

                  BackButtonWidget(
                    onPressed: onBack,
                  ),

                  SizedBox(height: h * .03),

                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 28,
                        color: Color(0xFF212121),
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: 'Escolha qual o\n',
                        ),
                        TextSpan(
                          text: 'tipo de conta:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * .05),

                  BorderCardWidget(
                    leading: Image.asset(
                      AssetPaths.elderAvatar,
                      width: 100,
                      height: 100,
                    ),
                    title: 'Para idosos',
                    description:
                        'Visualiza suas tarefas e rotina de forma simples e prática.',
                    onTap: () => _navigate(
                      context,
                      AccountType.elder,
                    ),
                  ),

                  SizedBox(height: h * .025),

                  BorderCardWidget(
                    leading: Image.asset(
                      AssetPaths.caregiverAvatar,
                      width: 100,
                      height: 100,
                    ),
                    title: 'Para cuidadores',
                    description:
                        'Gerencie e atualize as atividades e cuidados do idoso.',
                    onTap: () => _navigate(
                      context,
                      AccountType.caregiver,
                    ),
                  ),

                  SizedBox(height: h * .025),

                  BorderCardWidget(
                    leading: Image.asset(
                      AssetPaths.familyAvatar,
                      width: 100,
                      height: 100,
                    ),
                    title: 'Para familiares',
                    description:
                        'Acompanhe a rotina do idoso e envie mensagens à distância.',
                    onTap: () => _navigate(
                      context,
                      AccountType.family,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}