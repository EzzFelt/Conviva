import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/formatters/brazilian_phone_formatter.dart';
import '../../../shared/widgets/app_modal_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/info_card_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/institution_summary.dart';
import '../providers/institution_summary_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  String _errorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
  }

  Future<void> _goHome(
    BuildContext context,
    UserSession session,
  ) async {
    await AuthenticatedUserNavigator.open(context, session);
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showAppModal<bool>(
      context: context,
      size: AppModalSize.small,
      showCloseButton: false,
      child: Builder(
        builder: (modalContext) {
          final theme = Theme.of(modalContext);
          final sizes = modalContext.appSizes;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tem certeza que deseja\nsair da sua conta?',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: sizes.lg),
              Row(
                children: [
                  Expanded(
                    child: ButtonWidget(
                      label: 'Sim',
                      size: ButtonSize.small,
                      variant: ButtonVariant.secondary,
                      onPressed: () {
                        Navigator.of(modalContext).pop(true);
                      },
                    ),
                  ),
                  SizedBox(width: sizes.md),
                  Expanded(
                    child: ButtonWidget(
                      label: 'Não',
                      size: ButtonSize.small,
                      variant: ButtonVariant.outlined,
                      onPressed: () {
                        Navigator.of(modalContext).pop(false);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    await ref.read(currentUserProvider.notifier).signOut();
    if (!context.mounted) return;
    context.go(RouteNames.onboarding);
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    UserSession session,
  ) async {
    final nameController = TextEditingController(text: session.name);
    final phoneController = TextEditingController(
      text: BrazilianPhoneFormatter.format(session.phone),
    );
    final formKey = GlobalKey<FormState>();
    var isSaving = false;
    String? errorMessage;

    await showAppModal<void>(
      context: context,
      size: AppModalSize.medium,
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          final theme = Theme.of(modalContext);
          final colorScheme = theme.colorScheme;
          final sizes = modalContext.appSizes;

          Future<void> save() async {
            if (!(formKey.currentState?.validate() ?? false)) return;

            setModalState(() {
              isSaving = true;
              errorMessage = null;
            });

            try {
              await ref.read(currentUserProvider.notifier).updateProfile(
                    name: nameController.text,
                    phone: phoneController.text,
                  );

              if (!modalContext.mounted) return;
              Navigator.of(modalContext).pop();
            } catch (error) {
              if (!modalContext.mounted) return;
              setModalState(() {
                isSaving = false;
                errorMessage = _errorMessage(error);
              });
            }
          }

          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nome completo:',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: sizes.sm),
                TextFieldWidget(
                  controller: nameController,
                  hintText: 'Nome completo',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome completo.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: sizes.md),
                Text(
                  'Telefone:',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: sizes.sm),
                TextFieldWidget(
                  controller: phoneController,
                  hintText: '(00) 00000-0000',
                  keyboardType: TextInputType.phone,
                  inputFormatters: const [BrazilianPhoneFormatter()],
                  validator: (value) {
                    final digits = BrazilianPhoneFormatter.digitsOnly(
                      value ?? '',
                    );
                    if (digits.length < 10 || digits.length > 11) {
                      return 'Informe um telefone válido.';
                    }
                    return null;
                  },
                ),
                if (errorMessage != null) ...[
                  SizedBox(height: sizes.md),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
                SizedBox(height: sizes.xxl),
                ButtonWidget(
                  label: isSaving ? 'Salvando...' : 'Salvar',
                  variant: ButtonVariant.secondary,
                  onPressed: isSaving ? null : save,
                ),
                SizedBox(height: sizes.md),
                ButtonWidget(
                  label: 'Cancelar',
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(modalContext).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );

    nameController.dispose();
    phoneController.dispose();
  }

  Widget _avatar(BuildContext context, UserSession session) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final photoUrl = session.photoUrl?.trim();

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: sizes.xs),
      ),
      child: CircleAvatar(
        radius: sizes.xxl,
        backgroundColor: colorScheme.primary.withValues(alpha: .14),
        child: photoUrl != null && photoUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  photoUrl,
                  width: sizes.xxl * 2,
                  height: sizes.xxl * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.person_rounded,
                    size: sizes.icon(sizes.xxl),
                    color: colorScheme.primary,
                  ),
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: sizes.icon(sizes.xxl),
                color: colorScheme.primary,
              ),
      ),
    );
  }

  Widget _institutionVisual(
    BuildContext context,
    String? photoUrl,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final normalizedPhotoUrl = photoUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(sizes.radiusSm),
      child: ColoredBox(
        color: colorScheme.primary.withValues(alpha: .14),
        child: normalizedPhotoUrl != null && normalizedPhotoUrl.isNotEmpty
            ? Image.network(
                normalizedPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.apartment_rounded,
                  color: colorScheme.primary,
                  size: sizes.icon(sizes.lg),
                ),
              )
            : Icon(
                Icons.apartment_rounded,
                color: colorScheme.primary,
                size: sizes.icon(sizes.lg),
              ),
      ),
    );
  }

  Widget _institutionCard(
    BuildContext context,
    AsyncValue<InstitutionSummary> institutionState,
    String institutionId,
  ) {
    final sizes = context.appSizes;
    final borderRadius = BorderRadius.circular(sizes.radiusMd);

    return institutionState.when(
      loading: () => InfoCardWidget(
        leading: const CircularProgressIndicator(),
        title: 'Carregando instituição',
        subtitle: 'Aguarde um momento...',
        size: InfoCardSize.small,
        borderRadius: borderRadius,
      ),
      error: (_, _) => InfoCardWidget(
        leading: _institutionVisual(context, null),
        title: 'Instituição',
        subtitle: 'Código: $institutionId',
        size: InfoCardSize.small,
        borderRadius: borderRadius,
      ),
      data: (institution) => InfoCardWidget(
        leading: _institutionVisual(context, institution.photoUrl),
        title: institution.name,
        subtitle: institution.address,
        size: InfoCardSize.small,
        borderRadius: borderRadius,
      ),
    );
  }

  Widget _informationCard(
    BuildContext context,
    WidgetRef ref,
    UserSession session,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final phone = session.phone.isEmpty
        ? 'Não informado'
        : BrazilianPhoneFormatter.format(session.phone);

    return InfoCardWidget(
      size: InfoCardSize.small,
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nome completo:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: sizes.xs),
          Text(session.name, style: theme.textTheme.bodySmall),
          SizedBox(height: sizes.sm),
          Text(
            'Telefone:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: sizes.xs),
          Text(phone, style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: IconButton.filled(
        tooltip: 'Editar informações',
        onPressed: () => _editProfile(context, ref, session),
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        icon: Icon(
          Icons.edit_rounded,
          size: sizes.icon(sizes.md),
        ),
      ),
    );
  }

  Widget _profilePanelContent(
    BuildContext context,
    WidgetRef ref,
    UserSession session,
    AsyncValue<InstitutionSummary> institutionState,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final phone = session.phone.isEmpty
        ? 'Não informado'
        : BrazilianPhoneFormatter.format(session.phone);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: sizes.xxl * 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            session.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: sizes.xs),
          Text(
            phone,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: sizes.lg),
          Text('Instituto', style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.sm),
          _institutionCard(
            context,
            institutionState,
            session.institutionId,
          ),
          SizedBox(height: sizes.lg),
          Text(
            'Suas informações',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: sizes.sm),
          _informationCard(context, ref, session),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    UserSession session,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final institutionState = ref.watch(
      institutionSummaryProvider(session.institutionId),
    );
    final panelRadius = Radius.elliptical(
      MediaQuery.sizeOf(context).width / 2,
      sizes.xxl * 1.5,
    );

    return DecoratedBox(
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
              title: 'Seu Perfil',
              onBackPressed: () => _goHome(context, session),
              trailing: IconButton(
                tooltip: 'Sair da conta',
                onPressed: () => _confirmSignOut(context, ref),
                icon: Icon(
                  Icons.logout_rounded,
                  color: colorScheme.onPrimary,
                  size: sizes.icon(sizes.lg),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: sizes.xl,
                    child: ContentPanelWidget(
                      borderRadius: BorderRadius.only(
                        topLeft: panelRadius,
                        topRight: panelRadius,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        sizes.lg,
                        sizes.xxl + sizes.lg,
                        sizes.lg,
                        0,
                      ),
                      child: _profilePanelContent(
                        context,
                        ref,
                        session,
                        institutionState,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(child: _avatar(context, session)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final sizes = context.appSizes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: currentUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(sizes.lg),
            child: Text(
              _errorMessage(error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Usuário não autenticado.'));
          }

          return _content(context, ref, session);
        },
      ),
    );
  }
}
