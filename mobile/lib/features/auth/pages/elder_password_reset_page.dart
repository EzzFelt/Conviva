import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/elder_password_reset_service.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/password_text_field_widget.dart';
import '../models/auth_arguments.dart';
import '../models/account_type.dart';
import '../models/auth_mode.dart';
import '../models/elder_password_reset_request.dart';
import '../widgets/auth_header_widget.dart';

class ElderPasswordResetPage extends StatefulWidget {
  const ElderPasswordResetPage({super.key, required this.request});

  final ElderPasswordResetRequest request;

  @override
  State<ElderPasswordResetPage> createState() => _ElderPasswordResetPageState();
}

class _ElderPasswordResetPageState extends State<ElderPasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) {
      return 'As senhas não coincidem.';
    }
    return null;
  }

  Future<void> _savePassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await ElderPasswordResetService.instance.complete(
        request: widget.request,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      context.go(
        RouteNames.elderLogin,
        extra: const AuthArguments(
          accountType: AccountType.elder,
          authMode: AuthMode.login,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message =
          ElderPasswordResetService.callableErrorMessage(error) ??
          error.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Não foi possível trocar a senha. Tente novamente.'
                : message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.appSizes;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: sizes.lg,
            vertical: sizes.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: sizes.xl),
                const AuthHeaderWidget(title: 'Crie uma\nnova senha'),
                SizedBox(height: sizes.md),
                Text(
                  'A solicitação foi aprovada. Escolha uma nova senha para '
                  'acessar sua conta.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: sizes.xl),
                PasswordTextFieldWidget(
                  controller: _passwordController,
                  enabled: !_isSaving,
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: sizes.md),
                PasswordTextFieldWidget(
                  controller: _confirmationController,
                  enabled: !_isSaving,
                  hintText: 'Confirme a nova senha',
                  validator: _validateConfirmation,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _savePassword(),
                ),
                SizedBox(height: sizes.xl),
                ButtonWidget(
                  label: _isSaving ? 'Salvando...' : 'Salvar nova senha',
                  variant: ButtonVariant.primary,
                  onPressed: _isSaving ? null : _savePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
