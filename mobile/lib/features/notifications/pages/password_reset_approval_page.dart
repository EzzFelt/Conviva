import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/elder_recovery_request_service.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../auth/models/elder_recovery_request.dart';

/// Tela em que o familiar ou cuidador aprova (ou recusa) o pedido de troca de
/// senha de um idoso e, depois, encaminha o link recebido do suporte.
class PasswordResetApprovalPage extends StatefulWidget {
  const PasswordResetApprovalPage({super.key, required this.requestId});

  final String requestId;

  @override
  State<PasswordResetApprovalPage> createState() =>
      _PasswordResetApprovalPageState();
}

class _PasswordResetApprovalPageState extends State<PasswordResetApprovalPage> {
  bool _isResponding = false;
  bool _isForwarding = false;

  // O stream é criado uma única vez. Criar dentro do build() reabria a
  // consulta a cada setState e fazia a tela piscar com o carregamento.
  Stream<ElderRecoveryRequest>? _requestStream;

  @override
  void initState() {
    super.initState();
    try {
      _requestStream = ElderRecoveryRequestService.instance
          .watchApprovalRequest(widget.requestId);
    } on StateError {
      _requestStream = null;
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.splash);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _respond(bool approve) async {
    if (_isResponding) return;
    setState(() => _isResponding = true);

    try {
      await ElderRecoveryRequestService.instance.respond(
        requestId: widget.requestId,
        approve: approve,
      );
      if (!mounted) return;
      _showMessage(
        approve
            ? 'A troca de senha foi aprovada.'
            : 'A solicitação foi recusada.',
      );
      _goBack();
    } catch (error) {
      _showMessage(
        error is StateError
            ? error.message.toString()
            : 'Não foi possível responder à solicitação. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

  Future<void> _forwardLink() async {
    if (_isForwarding) return;
    setState(() => _isForwarding = true);

    try {
      await ElderRecoveryRequestService.instance.forwardResetLinkToElder(
        widget.requestId,
      );
      _showMessage('Link encaminhado ao idoso.');
    } catch (error) {
      _showMessage(
        error is StateError
            ? error.message.toString()
            : 'Não foi possível encaminhar o link. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _isForwarding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ovalRadius = Radius.elliptical(screenWidth * .27, sizes.xxl);

    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.appGradientColors.bottom,
                context.appGradientColors.top,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                PageHeaderWidget(
                  title: 'Troca de senha',
                  onBackPressed: _goBack,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: ContentPanelWidget(
                            borderRadius: BorderRadius.only(
                              topLeft: ovalRadius,
                              topRight: ovalRadius,
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                sizes.lg,
                                sizes.xl,
                                sizes.lg,
                                sizes.xxl,
                              ),
                              child: _buildBody(context),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final stream = _requestStream;

    Widget centeredMessage(String text) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    const unavailable =
        'Não foi possível carregar este pedido. Ele pode ter expirado, já ter '
        'sido respondido ou não pertencer à sua conta.';

    if (stream == null) return centeredMessage(unavailable);

    return StreamBuilder<ElderRecoveryRequest>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return centeredMessage(unavailable);
        if (!snapshot.hasData) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: sizes.xl),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final request = snapshot.data!;
        final isPending = request.status == 'pending' && !request.isExpired;
        final isApprover =
            FirebaseAuth.instance.currentUser?.uid == request.approvedByUid;
        final statusMessage = switch (request.status) {
          'approved' => 'Este pedido já foi aprovado.',
          'rejected' => 'Este pedido já foi recusado.',
          'completed' => 'A equipe de suporte já concluiu este pedido.',
          _ when request.isExpired => 'Este pedido expirou após 24 horas.',
          _ => 'A primeira resposta de um dos responsáveis encerra o pedido.',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: sizes.xxl + sizes.lg,
                height: sizes.xxl + sizes.lg,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(sizes.radiusMd),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: sizes.icon(sizes.xl + sizes.sm),
                  color: colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: sizes.lg),
            Text(
              '${request.elderName ?? 'O idoso'} pediu para redefinir a '
              'senha da conta.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: sizes.md),
            Text(
              'Aprove somente se você reconhece e autoriza este pedido. A '
              'resposta será compartilhada com o idoso.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: sizes.lg),
            Container(
              padding: EdgeInsets.all(sizes.md),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(sizes.radiusMd),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: .3),
                ),
              ),
              child: Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: sizes.xl),
            if (isPending) ...[
              ButtonWidget(
                label: _isResponding ? 'Aguarde...' : 'Aprovar troca de senha',
                onPressed: _isResponding ? null : () => _respond(true),
              ),
              SizedBox(height: sizes.md),
              ButtonWidget(
                label: 'Recusar solicitação',
                variant: ButtonVariant.outlined,
                onPressed: _isResponding ? null : () => _respond(false),
              ),
            ] else if (request.status == 'approved' && isApprover) ...[
              if (request.deliveryForwardedToElder)
                Text(
                  'O link já foi encaminhado à sessão privada do idoso.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                )
              else if (request.linkDeliveredToApprover)
                ButtonWidget(
                  label: _isForwarding
                      ? 'Encaminhando...'
                      : 'Encaminhar link ao idoso',
                  onPressed: request.isExpired || _isForwarding
                      ? null
                      : _forwardLink,
                )
              else
                Text(
                  'A equipe de suporte ainda não disponibilizou o link. '
                  'Assim que ele estiver pronto, o botão para encaminhar ao '
                  'idoso aparece aqui.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ],
        );
      },
    );
  }
}
