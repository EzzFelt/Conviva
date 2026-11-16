import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/back_button_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';
import '../models/account_type.dart';
import '../models/auth_arguments.dart';
import '../models/auth_error_message.dart';
import '../widgets/auth_header_widget.dart';

/// O Firebase envia o link de redefinição para a conta ou para o suporte do
/// idoso, sem exigir um serviço de e-mail próprio.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.arguments});

  final AuthArguments arguments;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const _resendDelay = 30;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _timer;
  bool _isSending = false;
  bool _sent = false;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isElder => widget.arguments.accountType == AccountType.elder;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Informe o e-mail';

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Informe um e-mail válido';

    return null;
  }

  String? _validateCode(String? value) {
    final code = (value ?? '').trim().toUpperCase();

    if (code.isEmpty) return 'Informe o código de acesso';
    if (!RegExp(r'^ELD[A-Z0-9]{4,}$').hasMatch(code)) {
      return 'Informe um código válido (ELD...)';
    }

    return null;
  }

  String _errorText(Object error) {
    if (_isElder &&
        error is FirebaseAuthException &&
        error.code == 'user-not-found') {
      return 'Não encontramos uma conta para esse código. '
          'Confira o código e tente novamente.';
    }

    if (error is FirebaseException) {
      return AuthErrorMessage.from(error, context: AuthErrorContext.login);
    }

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty
        ? 'Não foi possível enviar agora. Tente novamente.'
        : message;
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendDelay);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSending || _secondsLeft > 0) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);

    try {
      if (_isElder) {
        await AuthService.instance.sendElderPasswordReset(
          _codeController.text.trim().toUpperCase(),
        );
      } else {
        await AuthService.instance.sendPasswordResetEmail(
          _emailController.text,
        );
      }

      if (!mounted) return;
      setState(() => _sent = true);
      _startCooldown();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _backToLogin() {
    context.go(
      _isElder ? RouteNames.elderLogin : RouteNames.login,
      extra: widget.arguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    final buttonLabel = _isSending
        ? 'Enviando...'
        : _secondsLeft > 0
        ? 'Reenviar em ${_secondsLeft}s'
        : _sent
        ? 'Reenviar link'
        : 'Enviar link';

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                BackButtonWidget(onPressed: _backToLogin),
                SizedBox(height: sizes.xl),
                const AuthHeaderWidget(title: 'Recupere\nsua senha'),
                SizedBox(height: sizes.md),
                Text(
                  _isElder
                      ? 'Digite o seu código de acesso (ELD...). O link de '
                            'redefinição será enviado à caixa de suporte do '
                            'Conviva.'
                      : 'Digite o e-mail da sua conta. Enviaremos um link para '
                            'você criar uma nova senha.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: sizes.xl),
                if (_isElder)
                  TextFieldWidget(
                    controller: _codeController,
                    hintText: 'Código de acesso (ELD...)',
                    enabled: !_isSending,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (_, newValue) => newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                        ),
                      ),
                    ],
                    textInputAction: TextInputAction.done,
                    validator: _validateCode,
                    onFieldSubmitted: (_) => _send(),
                  )
                else
                  TextFieldWidget(
                    controller: _emailController,
                    hintText: 'E-mail',
                    enabled: !_isSending,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: _validateEmail,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => _send(),
                  ),
                if (_sent) ...[
                  SizedBox(height: sizes.md),
                  Text(
                    _isElder
                        ? 'Solicitação enviada. Confira a caixa de suporte do '
                              'Conviva e também a pasta de spam.'
                        : 'Se existir uma conta com esse e-mail, o link já '
                              'está a caminho. Confira também a caixa de spam.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
                SizedBox(height: sizes.xl),
                ButtonWidget(
                  label: buttonLabel,
                  variant: ButtonVariant.primary,
                  onPressed: (_isSending || _secondsLeft > 0) ? null : _send,
                ),
                SizedBox(height: sizes.md),
                ButtonWidget(
                  label: 'Voltar para o login',
                  variant: ButtonVariant.outlined,
                  onPressed: _backToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
