import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';

import '../../../shared/widgets/back_button_widget.dart';
import '../../../shared/widgets/border_card_widget.dart';

import '../../auth/models/account_type.dart';
import '../../auth/models/auth_arguments.dart';
import '../../auth/models/auth_mode.dart';

class AccountTypePage extends StatelessWidget {
  const AccountTypePage({
    super.key,
    required this.onBack,
    required this.authMode,
  });

  final VoidCallback onBack;
  final AuthMode authMode;

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
    final theme = Theme.of(context);
    final sizes = context.appSizes;
    final avatarSize = sizes.xxl * 2;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(sizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButtonWidget(
                onPressed: onBack,
              ),

              SizedBox(height: sizes.lg),

              Semantics(
                header: true,
                child: Text(
                  'Escolha qual o\ntipo de conta:',
                  style: theme.textTheme.headlineLarge,
                ),
              ),

              SizedBox(height: sizes.xl),

              BorderCardWidget(
                leading: Image.asset(
                  AssetPaths.elderAvatar,
                  width: avatarSize,
                  height: avatarSize,
                  excludeFromSemantics: true,
                ),
                title: 'Para idosos',
                description:
                    'Visualiza suas tarefas e rotina de forma simples e prática.',
                onTap: () => _navigate(
                  context,
                  AccountType.elder,
                ),
              ),

              SizedBox(height: sizes.md),

              BorderCardWidget(
                leading: Image.asset(
                  AssetPaths.caregiverAvatar,
                  width: avatarSize,
                  height: avatarSize,
                  excludeFromSemantics: true,
                ),
                title: 'Para cuidadores',
                description:
                    'Gerencie e atualize as atividades e cuidados do idoso.',
                onTap: () => _navigate(
                  context,
                  AccountType.caregiver,
                ),
              ),

              SizedBox(height: sizes.md),

              BorderCardWidget(
                leading: Image.asset(
                  AssetPaths.familyAvatar,
                  width: avatarSize,
                  height: avatarSize,
                  excludeFromSemantics: true,
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
        ),
      ),
    );
  }
}
