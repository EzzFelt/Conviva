import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/elder_recovery_request_service.dart';
import '../../../shared/widgets/back_button_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';
import '../models/account_type.dart';
import '../models/auth_arguments.dart';
import '../models/auth_error_message.dart';
import '../models/elder_recovery_request.dart';
import '../widgets/auth_header_widget.dart';

/// Registra a solicitação de recuperação do idoso ou envia o link por e-mail.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.arguments});

  final AuthArguments arguments;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const _emailResendDelay = Duration(seconds: 30);
  static const _elderResendDelay = Duration(minutes: 5);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _timer;
  Timer? _requestExpiryTimer;
  StreamSubscription<ElderRecoveryRequest>? _requestSubscription;
  bool _isSending = false;
  bool _sent = false;
  String? _requestStatus;
  String? _activeRequestId;
  String? _resetLink;
  bool _isLoadingResetLink = false;
  bool _deliveryForwardedToElder = false;
  bool _requestTrackingFailed = false;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    if (_isElder) unawaited(_restoreRequest());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _requestExpiryTimer?.cancel();
    _requestSubscription?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isElder => widget.arguments.accountType == AccountType.elder;

  Future<void> _restoreRequest() async {
    try {
      final request = await ElderRecoveryRequestService.instance
          .findLatestRequestForCurrentSession();
      if (!mounted || request == null) return;

      setState(() {
        _sent = true;
        _requestStatus = request.isExpired ? 'expired' : request.status;
        _activeRequestId = request.id;
        _deliveryForwardedToElder = request.deliveryForwardedToElder;
        if (request.isExpired) _resetLink = null;
      });
      _scheduleRequestExpiry(request);
      _watchRequestStatus(request.id);
    } on FirebaseException {
      if (!mounted) return;
      setState(() {
        _sent = true;
        _requestTrackingFailed = true;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _sent = true;
        _requestTrackingFailed = true;
      });
    }
  }

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
    if (error is RecoveryContactsNotConfiguredException) {
      return error.toString();
    }

    if (error is RecoveryRequestRejectedException) {
      return error.toString();
    }

    if (error is FirebaseException) {
      return AuthErrorMessage.from(error, context: AuthErrorContext.login);
    }

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty
        ? 'Não foi possível enviar agora. Tente novamente.'
        : message;
  }

  void _startCooldown(Duration delay) {
    _timer?.cancel();
    setState(() => _secondsLeft = delay.inSeconds);

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
        final requestId = await ElderRecoveryRequestService.instance.request(
          _codeController.text,
        );
        if (!mounted) return;
        setState(() {
          _sent = true;
          _requestStatus = 'pending';
          _requestTrackingFailed = false;
          _activeRequestId = requestId;
          _resetLink = null;
          _deliveryForwardedToElder = false;
        });
        _requestExpiryTimer?.cancel();
        _watchRequestStatus(requestId);
      } else {
        await AuthService.instance.sendPasswordResetEmail(
          _emailController.text,
        );
        if (!mounted) return;
        setState(() => _sent = true);
      }

      _startCooldown(_isElder ? _elderResendDelay : _emailResendDelay);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _watchRequestStatus(String requestId) {
    _requestSubscription?.cancel();
    _requestSubscription = ElderRecoveryRequestService.instance
        .watchRequestStatus(requestId)
        .listen(
          (request) {
            if (!mounted) return;
            setState(() {
              _requestStatus = request.isExpired ? 'expired' : request.status;
              _activeRequestId = request.id;
              _deliveryForwardedToElder =
                  !request.isExpired && request.deliveryForwardedToElder;
              if (request.isExpired) _resetLink = null;
              _requestTrackingFailed = false;
            });
            _scheduleRequestExpiry(request);
            if (!request.isExpired &&
                request.deliveryForwardedToElder &&
                _resetLink == null) {
              unawaited(_loadResetLink(request.id));
            }
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() => _requestTrackingFailed = true);
          },
        );
  }

  void _scheduleRequestExpiry(ElderRecoveryRequest request) {
    _requestExpiryTimer?.cancel();
    final timeLeft = request.expiresAt.difference(DateTime.now());
    if (timeLeft <= Duration.zero) return;

    _requestExpiryTimer = Timer(timeLeft, () {
      if (!mounted) return;
      setState(() {
        _requestStatus = 'expired';
        _deliveryForwardedToElder = false;
        _resetLink = null;
      });
    });
  }

  Future<void> _loadResetLink(String requestId) async {
    if (_isLoadingResetLink || _resetLink != null) return;
    setState(() => _isLoadingResetLink = true);
    try {
      final link = await ElderRecoveryRequestService.instance
          .getResetLinkForCurrentSession(requestId);
      if (!mounted) return;
      setState(() => _resetLink = link);
    } on FirebaseException {
      if (!mounted) return;
      setState(() => _requestTrackingFailed = true);
    } on StateError {
      if (!mounted) return;
      setState(() => _requestTrackingFailed = true);
    } finally {
      if (mounted) setState(() => _isLoadingResetLink = false);
    }
  }

  Future<void> _copyResetLink() async {
    final resetLink = _resetLink;
    if (resetLink == null) return;
    await Clipboard.setData(ClipboardData(text: resetLink));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copiado.')));
  }

  Future<void> _openResetLink() async {
    final resetLink = _resetLink;
    if (resetLink == null) return;

    try {
      final opened = await launchUrl(
        Uri.parse(resetLink),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted || opened) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o link no navegador.'),
        ),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o link no navegador.'),
        ),
      );
    }
  }

  String _elderRequestMessage() {
    if (_requestTrackingFailed) {
      return 'O pedido foi registrado, mas não foi possível acompanhar '
          'a resposta agora.';
    }

    return switch (_requestStatus) {
      'approved' =>
        _deliveryForwardedToElder
            ? 'O responsável encaminhou o link de redefinição para esta sessão.'
            : 'Pedido aprovado. Aguarde o suporte disponibilizar o link.',
      'completed' => 'O pedido foi concluído pela equipe de suporte.',
      'rejected' =>
        'A solicitação foi recusada. Converse com os responsáveis antes de tentar novamente.',
      'expired' => 'O pedido expirou. Você pode iniciar uma nova solicitação.',
      _ =>
        'Pedido registrado. Aguarde a resposta de um dos responsáveis '
            'escolhidos no perfil.',
    };
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
        ? 'Tentar novamente em ${_secondsLeft}s'
        : _sent
        ? _isElder
              ? 'Solicitar novamente'
              : 'Reenviar link'
        : _isElder
        ? 'Enviar solicitação'
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
                      ? 'Digite o seu código de acesso (ELD...). Enviaremos '
                            'um pedido para os responsáveis que você escolheu '
                            'no perfil.'
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
                  _RecoveryNotice(
                    message: _isElder
                        ? _elderRequestMessage()
                        : 'Se existir uma conta com esse e-mail, o link já '
                              'está a caminho. Confira também a caixa de spam.',
                  ),
                  if (_isElder &&
                      _requestStatus != 'expired' &&
                      _deliveryForwardedToElder) ...[
                    SizedBox(height: sizes.md),
                    _ResetLinkPanel(
                      isLoading: _isLoadingResetLink,
                      resetLink: _resetLink,
                      onOpen: _openResetLink,
                      onCopy: _copyResetLink,
                      onRetry: _activeRequestId == null
                          ? null
                          : () => _loadResetLink(_activeRequestId!),
                    ),
                  ],
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

/// Aviso de andamento do pedido, no mesmo estilo das caixas do app.
class _RecoveryNotice extends StatelessWidget {
  const _RecoveryNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sizes.md),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(sizes.radiusMd),
        border: Border.all(color: colorScheme.primary.withValues(alpha: .3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: sizes.icon(sizes.lg),
            color: colorScheme.primary,
          ),
          SizedBox(width: sizes.sm),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Link de redefinição encaminhado pelo responsável ao idoso.
class _ResetLinkPanel extends StatelessWidget {
  const _ResetLinkPanel({
    required this.isLoading,
    required this.resetLink,
    required this.onOpen,
    required this.onCopy,
    required this.onRetry,
  });

  final bool isLoading;
  final String? resetLink;
  final VoidCallback onOpen;
  final VoidCallback onCopy;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final link = resetLink;

    return Material(
      color: colorScheme.surface,
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: .25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sizes.radiusMd + sizes.xs),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(
        padding: EdgeInsets.all(sizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Link para criar a nova senha',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: sizes.sm),
            if (isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: sizes.md),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (link != null) ...[
              Text(
                'Toque em "Abrir no navegador" e escolha a sua nova senha.',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: sizes.md),
              ButtonWidget(label: 'Abrir no navegador', onPressed: onOpen),
              SizedBox(height: sizes.sm),
              ButtonWidget(
                label: 'Copiar link',
                variant: ButtonVariant.outlined,
                onPressed: onCopy,
              ),
              SizedBox(height: sizes.md),
              Text(
                'Se o link expirou ou já foi usado, volte ao app e peça ao '
                'suporte um novo e-mail. Isso só é possível enquanto o pedido '
                'estiver válido.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Text(
                'Não foi possível carregar o link.',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: sizes.md),
              ButtonWidget(
                label: 'Tentar novamente',
                variant: ButtonVariant.outlined,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
