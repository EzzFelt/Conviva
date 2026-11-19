import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/elder_recovery_request_service.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/confirm_modal.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';
import '../../auth/models/account_type.dart';
import '../../auth/models/elder_recovery_request.dart';
import '../../auth/providers/current_user_provider.dart';
import '../providers/support_recovery_requests_provider.dart';

/// Painel da equipe de suporte para atender pedidos de recuperação de senha
/// do idoso.
///
/// O atendimento acontece em dois passos, sempre nesta ordem:
///  1. solicitar ao Firebase o e-mail de redefinição (precisa do código ELD);
///  2. copiar o link recebido na caixa do suporte e disponibilizá-lo ao
///     responsável que aprovou o pedido.
///
/// As regras do Firestore só aceitam o passo 2 depois que o passo 1 foi
/// registrado, por isso a tela mantém o passo 2 bloqueado até lá.
class SupportHomePage extends ConsumerStatefulWidget {
  const SupportHomePage({super.key});

  @override
  ConsumerState<SupportHomePage> createState() => _SupportHomePageState();
}

class _SupportHomePageState extends ConsumerState<SupportHomePage> {
  final Set<String> _deliveringLinkRequestIds = {};
  final Set<String> _requestingEmailIds = {};

  Future<void> _signOut() async {
    await ref.read(currentUserProvider.notifier).signOut();
    if (mounted) context.go(RouteNames.onboarding);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage('$label copiado.');
  }

  String _accountTypeLabel(String? accountType) {
    return switch (accountType) {
      'family' => 'familiar',
      'caregiver' => 'cuidador',
      _ => 'responsável',
    };
  }

  Future<bool> _requestResetEmail(
    ElderRecoveryRequest request,
    String elderCode,
  ) async {
    final confirmed = await showConfirmModal(
      context,
      title: 'Solicitar e-mail',
      message:
          'O Firebase vai enviar o e-mail de redefinição para a caixa do '
          'suporte. Um novo envio só é possível depois de 5 minutos.',
      confirmLabel: 'Solicitar e-mail',
    );
    if (!confirmed || !mounted) return false;

    setState(() => _requestingEmailIds.add(request.id));
    try {
      await ElderRecoveryRequestService.instance.requestResetEmail(
        requestId: request.id,
        elderCode: elderCode,
      );
      _showMessage(
        'Pedido enviado ao Firebase. Abra a caixa do suporte, copie o link '
        'do e-mail e siga para o passo 2.',
      );
      return true;
    } on StateError catch (error) {
      _showMessage(error.message.toString());
    } on FirebaseAuthException catch (error) {
      _showMessage(switch (error.code) {
        'too-many-requests' =>
          'O Firebase limitou os envios por agora. Aguarde alguns minutos.',
        'invalid-email' ||
        'user-not-found' =>
          'O Firebase não encontrou uma conta para esse código ELD.',
        'network-request-failed' =>
          'Sem conexão com a internet. Tente novamente.',
        _ => 'Não foi possível pedir o e-mail ao Firebase (${error.code}).',
      });
    } on FirebaseException catch (error) {
      _showMessage(
        error.code == 'permission-denied'
            ? 'Não foi possível solicitar agora. Aguarde 5 minutos desde o '
                  'último pedido e confira se o pedido continua aprovado.'
            : 'Não foi possível solicitar o e-mail. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _requestingEmailIds.remove(request.id));
    }
    return false;
  }

  Future<bool> _deliverResetLink(
    ElderRecoveryRequest request,
    String resetLink,
  ) async {
    final approvedByUid = request.approvedByUid;
    if (approvedByUid == null) return false;

    final confirmed = await showConfirmModal(
      context,
      title: 'Disponibilizar link',
      message:
          'O link ficará disponível somente para o '
          '${_accountTypeLabel(request.approvedByType)} que aprovou este '
          'pedido ($approvedByUid). Confirme que é o link mais recente.',
      confirmLabel: 'Disponibilizar',
    );
    if (!confirmed || !mounted) return false;

    setState(() => _deliveringLinkRequestIds.add(request.id));
    try {
      await ElderRecoveryRequestService.instance.deliverResetLink(
        requestId: request.id,
        resetLink: resetLink,
      );
      _showMessage('Link disponibilizado ao responsável.');
      return true;
    } on StateError catch (error) {
      _showMessage(error.message.toString());
    } on FirebaseException {
      _showMessage('Não foi possível disponibilizar o link. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _deliveringLinkRequestIds.remove(request.id));
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final sizes = context.appSizes;

    return session.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(sizes.lg),
            child: Text(
              'Não foi possível validar a conta de suporte.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (user) {
        if (user?.accountType != AccountType.support) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(sizes.lg),
                child: ButtonWidget(
                  label: 'Voltar ao início',
                  onPressed: () => context.go(RouteNames.onboarding),
                ),
              ),
            ),
          );
        }

        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
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
                  title: 'Suporte Conviva',
                  onBackPressed: _signOut,
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
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const _HowToCard(),
                                      SizedBox(height: sizes.lg),
                                      Text(
                                        'Pedidos aprovados',
                                        style: theme.textTheme.headlineSmall,
                                      ),
                                      SizedBox(height: sizes.md),
                                      _buildRequestList(context),
                                      SizedBox(height: sizes.lg),
                                      ButtonWidget(
                                        label: 'Sair da conta',
                                        variant: ButtonVariant.outlined,
                                        onPressed: _signOut,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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

  Widget _buildRequestList(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.appSizes;
    final requests = ref.watch(supportRecoveryRequestsProvider);

    Widget message(String text) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.lg),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return requests.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.xl),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) =>
          message('Não foi possível carregar os pedidos aprovados.'),
      data: (items) {
        if (items.isEmpty) {
          return message('Não há pedidos aprovados aguardando atendimento.');
        }

        return Column(
          children: [
            for (final request in items) ...[
              _SupportRequestCard(
                key: ValueKey(request.id),
                request: request,
                isDeliveringLink: _deliveringLinkRequestIds.contains(
                  request.id,
                ),
                isRequestingEmail: _requestingEmailIds.contains(request.id),
                onCopy: _copy,
                onDeliverLink: (link) => _deliverResetLink(request, link),
                onRequestEmail: (code) => _requestResetEmail(request, code),
              ),
              SizedBox(height: sizes.md),
            ],
          ],
        );
      },
    );
  }
}

/// Caixa com o passo a passo do atendimento.
class _HowToCard extends StatelessWidget {
  const _HowToCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    Widget step(String number, String text) {
      return Padding(
        padding: EdgeInsets.only(top: sizes.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepBadge(label: number, size: sizes.lg),
            SizedBox(width: sizes.sm),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(sizes.md),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(sizes.radiusMd + sizes.xs),
        border: Border.all(color: colorScheme.primary.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como atender uma solicitação',
            style: theme.textTheme.titleMedium,
          ),
          step(
            '1',
            'Digite o código ELD do idoso e peça o e-mail de redefinição ao '
                'Firebase.',
          ),
          step(
            '2',
            'Abra a caixa do suporte e copie o link que chegou no e-mail.',
          ),
          step(
            '3',
            'Cole o link e disponibilize ao responsável que aprovou. Ele '
                'encaminha o link ao idoso pelo app.',
          ),
          SizedBox(height: sizes.sm),
          Text(
            'A conta de suporte não dá acesso ao Console.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.label,
    required this.size,
    this.done = false,
  });

  final String label;
  final double size;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: done
          ? Icon(
              Icons.check_rounded,
              size: size * .7,
              color: colorScheme.onPrimary,
            )
          : Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
    );
  }
}

class _SupportRequestCard extends StatefulWidget {
  const _SupportRequestCard({
    super.key,
    required this.request,
    required this.isDeliveringLink,
    required this.isRequestingEmail,
    required this.onCopy,
    required this.onDeliverLink,
    required this.onRequestEmail,
  });

  final ElderRecoveryRequest request;
  final bool isDeliveringLink;
  final bool isRequestingEmail;
  final void Function(String text, String label) onCopy;
  final Future<bool> Function(String link) onDeliverLink;
  final Future<bool> Function(String code) onRequestEmail;

  @override
  State<_SupportRequestCard> createState() => _SupportRequestCardState();
}

class _SupportRequestCardState extends State<_SupportRequestCard> {
  final _codeController = TextEditingController();
  final _linkController = TextEditingController();
  Timer? _cooldownTimer;
  bool _wasCoolingDown = false;

  @override
  void initState() {
    super.initState();
    // Atualiza a contagem dos 5 minutos entre envios de e-mail.
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final active =
          widget.request.resetEmailCooldownRemaining > Duration.zero;
      if (active || _wasCoolingDown) {
        setState(() => _wasCoolingDown = active);
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailRequest() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final requested = await widget.onRequestEmail(_codeController.text);
    if (requested && mounted) setState(_codeController.clear);
  }

  Future<void> _submitLink() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final delivered = await widget.onDeliverLink(_linkController.text.trim());
    if (delivered && mounted) setState(_linkController.clear);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} às $hour:$minute';
  }

  String _formatCooldown(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final request = widget.request;
    final expired = request.isExpired;

    final codeText = _codeController.text.trim();
    final codeValid = ElderRecoveryRequestService.isValidElderCode(codeText);
    final cooldown = request.resetEmailCooldownRemaining;
    final canRequestEmail =
        !expired &&
        codeValid &&
        !widget.isRequestingEmail &&
        cooldown == Duration.zero;

    final linkText = _linkController.text.trim();
    final linkValid =
        linkText.isNotEmpty &&
        ElderRecoveryRequestService.instance.isValidResetLink(linkText);
    final canEnterLink =
        !expired &&
        request.resetEmailRequested &&
        !request.linkDeliveredToApprover &&
        request.approvedByUid != null;
    final canDeliver = canEnterLink && linkValid && !widget.isDeliveringLink;

    final statusLabel = expired
        ? 'Pedido expirado'
        : request.deliveryForwardedToElder
        ? 'Link encaminhado ao idoso'
        : request.linkDeliveredToApprover
        ? 'Link com o responsável'
        : request.resetEmailRequested
        ? 'Aguardando o link do e-mail'
        : 'Aguardando o pedido do e-mail';

    final approverLabel = switch (request.approvedByType) {
      'family' => 'Familiar',
      'caregiver' => 'Cuidador',
      _ => 'Responsável',
    };

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
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sizes.md,
                  vertical: sizes.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: (expired ? colorScheme.error : colorScheme.primary)
                      .withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(sizes.radiusFull),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: expired ? colorScheme.error : colorScheme.primary,
                  ),
                ),
              ),
            ),
            SizedBox(height: sizes.md),
            _InfoRow(
              label: 'UID do idoso',
              value: request.elderUid,
              onCopy: () => widget.onCopy(request.elderUid, 'UID'),
            ),
            SizedBox(height: sizes.sm),
            _InfoRow(
              label: '$approverLabel que aprovou',
              value: request.approvedByUid ?? 'indisponível',
              onCopy: request.approvedByUid == null
                  ? null
                  : () => widget.onCopy(request.approvedByUid!, 'UID'),
            ),
            SizedBox(height: sizes.sm),
            Text(
              expired
                  ? 'O prazo de 24 horas terminou. Não conclua este pedido.'
                  : 'Prazo até ${_formatDate(request.expiresAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: expired
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (!expired) ...[
              Divider(height: sizes.xl, color: colorScheme.outline),

              // ---------- Passo 1 ----------
              Row(
                children: [
                  _StepBadge(
                    label: '1',
                    size: sizes.lg,
                    done: request.resetEmailRequested,
                  ),
                  SizedBox(width: sizes.sm),
                  Expanded(
                    child: Text(
                      'Pedir o e-mail de redefinição',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: sizes.sm),
              if (request.resetEmailRequested)
                Padding(
                  padding: EdgeInsets.only(bottom: sizes.sm),
                  child: Text(
                    'O Firebase aceitou o pedido. Confira a caixa do suporte: '
                    'isso não garante que o e-mail chegou.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              TextFieldWidget(
                controller: _codeController,
                hintText: 'Código ELD do idoso',
                enabled: !widget.isRequestingEmail,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  TextInputFormatter.withFunction(
                    (_, newValue) =>
                        newValue.copyWith(text: newValue.text.toUpperCase()),
                  ),
                ],
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) {
                  if (canRequestEmail) _submitEmailRequest();
                },
              ),
              if (codeText.isNotEmpty && !codeValid)
                Padding(
                  padding: EdgeInsets.only(top: sizes.xs, left: sizes.md),
                  child: Text(
                    'O código começa com ELD, seguido de letras e números.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              if (cooldown > Duration.zero)
                Padding(
                  padding: EdgeInsets.only(top: sizes.xs, left: sizes.md),
                  child: Text(
                    'Novo envio disponível em ${_formatCooldown(cooldown)}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              SizedBox(height: sizes.md),
              ButtonWidget(
                label: widget.isRequestingEmail
                    ? 'Solicitando...'
                    : request.resetEmailRequested ||
                          request.linkDeliveredToApprover
                    ? 'Pedir novo e-mail'
                    : 'Solicitar e-mail',
                variant: request.resetEmailRequested
                    ? ButtonVariant.outlined
                    : ButtonVariant.primary,
                onPressed: canRequestEmail ? _submitEmailRequest : null,
              ),
              Divider(height: sizes.xl, color: colorScheme.outline),

              // ---------- Passo 2 ----------
              Row(
                children: [
                  _StepBadge(
                    label: '2',
                    size: sizes.lg,
                    done: request.linkDeliveredToApprover,
                  ),
                  SizedBox(width: sizes.sm),
                  Expanded(
                    child: Text(
                      'Disponibilizar o link ao responsável',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: sizes.sm),
              if (request.linkDeliveredToApprover)
                Text(
                  request.deliveryForwardedToElder
                      ? 'O link foi encaminhado ao idoso.'
                      : 'O link já está disponível para o responsável. Se '
                            'ele vencer, peça um novo e-mail no passo 1.',
                  style: theme.textTheme.bodyMedium,
                )
              else ...[
                if (!request.resetEmailRequested)
                  Padding(
                    padding: EdgeInsets.only(bottom: sizes.sm),
                    child: Text(
                      'Disponível depois que o e-mail for solicitado no '
                      'passo 1.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                TextFieldWidget(
                  controller: _linkController,
                  hintText: 'Cole aqui o link do e-mail',
                  enabled: canEnterLink && !widget.isDeliveringLink,
                  keyboardType: TextInputType.url,
                  minLines: 1,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
                if (canEnterLink && linkText.isNotEmpty && !linkValid)
                  Padding(
                    padding: EdgeInsets.only(top: sizes.xs, left: sizes.md),
                    child: Text(
                      'Cole o link completo recebido do Firebase '
                      '(https://…/__/auth/action?mode=resetPassword…).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                SizedBox(height: sizes.md),
                ButtonWidget(
                  label: widget.isDeliveringLink
                      ? 'Disponibilizando...'
                      : 'Disponibilizar link',
                  onPressed: canDeliver ? _submitLink : null,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.onCopy});

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SelectableText(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            tooltip: 'Copiar',
            onPressed: onCopy,
            icon: Icon(
              Icons.copy_rounded,
              size: sizes.icon(sizes.lg),
              color: colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
