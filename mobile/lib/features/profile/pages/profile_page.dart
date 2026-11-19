import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:conviva/shared/utils/profile_image.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/family_link_id.dart';
import '../../../shared/formatters/brazilian_phone_formatter.dart';
import '../../../shared/widgets/app_modal_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/confirm_modal.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/info_card_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';
import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../routine/models/routine_elder_summary.dart';
import '../../routine/providers/routine_provider.dart';
import '../models/active_family_link.dart';
import '../models/family_link_request.dart';
import '../models/institution_summary.dart';
import '../providers/family_link_requests_provider.dart';
import '../providers/institution_summary_provider.dart';
import '../repositories/recovery_contacts_repository.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  String _errorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
  }

  Future<void> _goHome(BuildContext context, UserSession session) async {
    await AuthenticatedUserNavigator.open(context, session);
  }

  Future<void> _unlinkFamilyRelationship(
    BuildContext context,
    String linkId,
    String linkedName,
  ) async {
    final confirmed = await showConfirmModal(
      context,
      title: 'Desvincular vínculo?',
      message:
          'Deseja se desvincular de $linkedName? '
          'Você não terá mais acesso à rotina e à conversa.',
      confirmLabel: 'Desvincular',
    );

    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService.instance.unlinkFamilyRelationship(linkId);
      messenger.showSnackBar(
        SnackBar(content: Text('Vínculo com $linkedName desfeito.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível desfazer o vínculo. Tente novamente.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
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

  Future<void> _editProfile(BuildContext context, UserSession session) {
    return showAppModal<void>(
      context: context,
      size: AppModalSize.medium,
      child: _EditProfileForm(session: session),
    );
  }

  Widget _institutionVisual(BuildContext context, String? photoUrl) {
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

  Widget _institutionContent(
    BuildContext context, {
    required String name,
    String? address,
    String? code,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final hasAddress = address != null && address.isNotEmpty;
    final hasCode = code != null && code.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        if (hasAddress)
          Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        if (hasCode) ...[
          SizedBox(height: sizes.xs),
          Text(
            'Código: $code',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _institutionCard(
    BuildContext context,
    AsyncValue<InstitutionSummary> institutionState,
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
        content: _institutionContent(
          context,
          name: 'Instituição',
          address: 'Não foi possível carregar os dados.',
        ),
        size: InfoCardSize.small,
        borderRadius: borderRadius,
      ),
      data: (institution) => InfoCardWidget(
        leading: _institutionVisual(context, institution.photoUrl),
        content: _institutionContent(
          context,
          name: institution.name,
          address: institution.address,
          code: institution.code,
        ),
        size: InfoCardSize.small,
        borderRadius: borderRadius,
      ),
    );
  }

  Widget _sectionMessage(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.appSizes.md),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _linkedEldersSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<InstitutionSummary> institutionState,
    UserSession session,
  ) {
    final sizes = context.appSizes;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eldersState = ref.watch(accessibleRoutineEldersProvider);
    final institutionName = institutionState.value?.name;

    return eldersState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _sectionMessage(
        context,
        'Não foi possível carregar os parentes vinculados.',
      ),
      data: (elders) {
        return Column(
          children: [
            if (elders.isEmpty)
              _sectionMessage(context, 'Nenhum parente vinculado ainda.')
            else
              for (final elder in elders)
                Padding(
                  padding: EdgeInsets.only(bottom: sizes.sm),
                  child: _linkedElderCard(
                    context,
                    elder,
                    institutionName,
                    session,
                  ),
                ),
            SizedBox(height: sizes.md),
            Center(
              child: SizedBox(
                width: 280,
                child: OutlinedButton(
                  onPressed: () => context.push(RouteNames.familyLink),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(sizes.buttonMedium),
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sizes.radiusFull),
                    ),
                  ),
                  child: Text(
                    'Adicionar Familiar',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _linkedElderCard(
    BuildContext context,
    RoutineElderSummary elder,
    String? institutionName,
    UserSession session,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final photo = profileImageProvider(elder.photoUrl);
    final details = [
      if (institutionName != null && institutionName.isNotEmpty)
        institutionName,
      if (elder.createdAt != null) 'Desde ${elder.createdAt!.year}',
    ].join(' - ');

    return InfoCardWidget(
      size: InfoCardSize.small,
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: .14),
        foregroundImage: photo,
        child: photo == null
            ? Icon(Icons.person_rounded, color: colorScheme.primary)
            : null,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            elder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (details.isNotEmpty)
            Text(
              details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Desvincular idoso',
        onPressed: () => _unlinkFamilyRelationship(
          context,
          FamilyLinkId.forUsers(elderId: elder.id, familyId: session.uid),
          elder.name,
        ),
        icon: const Icon(Icons.link_off_rounded),
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
          if (session.accountType == AccountType.caregiver) ...[
            SizedBox(height: sizes.sm),
            Text(
              'Cargo:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: sizes.xs),
            Text(
              session.jobTitle.isEmpty ? 'Não informado' : session.jobTitle,
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: sizes.sm),
            Text(
              'Turno de trabalho:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: sizes.xs),
            Text(
              session.workShift.isEmpty ? 'Não informado' : session.workShift,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
      trailing: IconButton.filled(
        tooltip: 'Editar informações',
        onPressed: () => _editProfile(context, session),
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        icon: Icon(Icons.edit_rounded, size: sizes.icon(sizes.md)),
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
    final isFamily = session.accountType == AccountType.family;
    final isCaregiver = session.accountType == AccountType.caregiver;
    final phone = session.phone.isEmpty
        ? 'Não informado'
        : BrazilianPhoneFormatter.format(session.phone);
    final caregiverSubtitle = [
      if (session.phone.isNotEmpty) phone,
      if (session.jobTitle.isNotEmpty) session.jobTitle,
    ].join(' - ');
    final subtitle = isFamily
        ? (session.phone.isEmpty ? 'Parente' : '$phone - Parente')
        : isCaregiver
        ? (caregiverSubtitle.isEmpty ? 'Não informado' : caregiverSubtitle)
        : phone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          session.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: sizes.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: sizes.lg),
        if (session.accountType == AccountType.elder) ...[
          const _FamilyRequestsSection(),
          _ActiveFamilyLinksSection(
            onUnlink: (link) =>
                _unlinkFamilyRelationship(context, link.linkId, link.name),
          ),
          SizedBox(height: sizes.lg),
          Text(
            'Responsáveis pela recuperação',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: sizes.sm),
          const _RecoveryContactsSection(),
        ],
        if (isFamily) ...[
          Text('Parentes Vinculados', style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.sm),
          _linkedEldersSection(context, ref, institutionState, session),
        ] else ...[
          Text('Instituto', style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.sm),
          _institutionCard(context, institutionState),
        ],
        SizedBox(height: sizes.lg),
        Text('Suas informações', style: theme.textTheme.titleMedium),
        SizedBox(height: sizes.sm),
        _informationCard(context, ref, session),
        if (session.accountType == AccountType.elder) ...[
          SizedBox(height: sizes.lg),
          Text('Meu código de acesso', style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.sm),
          _AccessCodeCard(code: session.elderLinkCode),
        ],
      ],
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, UserSession session) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final bottomScrollPadding =
        sizes.lg +
        sizes.xxl +
        sizes.xl +
        sizes.sm +
        MediaQuery.viewPaddingOf(context).bottom +
        sizes.lg;
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeaderWidget(
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
            ),
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: sizes.xl),
                    child: ContentPanelWidget(
                      borderRadius: BorderRadius.only(
                        topLeft: panelRadius,
                        topRight: panelRadius,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        sizes.lg,
                        sizes.xxl + sizes.lg,
                        sizes.lg,
                        bottomScrollPadding,
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
                    child: Center(child: _ProfileAvatar(session: session)),
                  ),
                ],
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: ColoredBox(color: Theme.of(context).colorScheme.surface),
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
            child: Text(_errorMessage(error), textAlign: TextAlign.center),
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

/// Formulário de edição do perfil.
///
/// Os controllers e a chave do formulário pertencem ao State deste widget:
/// são descartados só quando o dialog sai da árvore (depois da animação de
/// fechamento), e não logo após o `pop`.
class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.session});

  final UserSession session;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _workShiftController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
    _phoneController = TextEditingController(
      text: BrazilianPhoneFormatter.format(widget.session.phone),
    );
    _jobTitleController = TextEditingController(text: widget.session.jobTitle);
    _workShiftController = TextEditingController(
      text: widget.session.workShift,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _workShiftController.dispose();
    super.dispose();
  }

  String _formatError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(currentUserProvider.notifier)
          .updateProfile(
            name: _nameController.text,
            phone: _phoneController.text,
            jobTitle: _jobTitleController.text,
            workShift: _workShiftController.text,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _formatError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nome completo:', style: theme.textTheme.bodySmall),
          SizedBox(height: sizes.sm),
          TextFieldWidget(
            controller: _nameController,
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
          Text('Telefone:', style: theme.textTheme.bodySmall),
          SizedBox(height: sizes.sm),
          TextFieldWidget(
            controller: _phoneController,
            hintText: '(00) 00000-0000',
            keyboardType: TextInputType.phone,
            inputFormatters: const [BrazilianPhoneFormatter()],
            validator: (value) {
              final digits = BrazilianPhoneFormatter.digitsOnly(value ?? '');
              if (digits.length < 10 || digits.length > 11) {
                return 'Informe um telefone válido.';
              }
              return null;
            },
          ),
          if (widget.session.accountType == AccountType.caregiver) ...[
            SizedBox(height: sizes.md),
            Text('Cargo:', style: theme.textTheme.bodySmall),
            SizedBox(height: sizes.sm),
            TextFieldWidget(
              controller: _jobTitleController,
              hintText: 'Ex.: Enfermeiro(a)',
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: sizes.md),
            Text('Turno de trabalho:', style: theme.textTheme.bodySmall),
            SizedBox(height: sizes.sm),
            TextFieldWidget(
              controller: _workShiftController,
              hintText: 'Ex.: Noturno - 19:00',
              textInputAction: TextInputAction.done,
            ),
          ],
          if (_errorMessage != null) ...[
            SizedBox(height: sizes.md),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          SizedBox(height: sizes.xxl),
          ButtonWidget(
            label: _isSaving ? 'Salvando...' : 'Salvar',
            variant: ButtonVariant.secondary,
            onPressed: _isSaving ? null : _save,
          ),
          SizedBox(height: sizes.md),
          ButtonWidget(
            label: 'Cancelar',
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

enum _PhotoAction { gallery, camera, remove }

/// Avatar do perfil com troca de foto (galeria, câmera ou remover).
class _ProfileAvatar extends ConsumerStatefulWidget {
  const _ProfileAvatar({required this.session});

  final UserSession session;

  @override
  ConsumerState<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<_ProfileAvatar> {
  bool _isBusy = false;

  bool get _hasPhoto => profileImageProvider(widget.session.photoUrl) != null;

  Future<void> _changePhoto() async {
    if (_isBusy) return;

    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(sheetContext, _PhotoAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(sheetContext, _PhotoAction.camera),
            ),
            if (_hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Remover foto'),
                onTap: () => Navigator.pop(sheetContext, _PhotoAction.remove),
              ),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(currentUserProvider.notifier);

    setState(() => _isBusy = true);

    try {
      if (action == _PhotoAction.remove) {
        await notifier.removeProfilePhoto();
      } else {
        final image = await ImagePicker().pickImage(
          source: action == _PhotoAction.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 70,
        );
        if (image == null) return;

        final bytes = await image.readAsBytes();
        final extension = image.name.contains('.')
            ? image.name.split('.').last
            : 'jpg';

        await notifier.updateProfilePhoto(bytes: bytes, extension: extension);
      }
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar a foto. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final photoUrl = widget.session.photoUrl?.trim();
    final photoProvider = profileImageProvider(photoUrl);
    final diameter = sizes.xxl * 2;

    return GestureDetector(
      onTap: _changePhoto,
      child: Semantics(
        button: true,
        label: 'Alterar foto de perfil',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary,
                  width: sizes.xs / 2,
                ),
              ),
              child: CircleAvatar(
                radius: sizes.xxl,
                backgroundColor: colorScheme.surface,
                child: ClipOval(
                  child: SizedBox.square(
                    dimension: diameter,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photoProvider != null)
                          Image(
                            image: photoProvider,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _fallbackIcon(colorScheme, sizes),
                          )
                        else
                          _fallbackIcon(colorScheme, sizes),
                        if (_isBusy)
                          ColoredBox(
                            color: colorScheme.surface.withValues(alpha: .6),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(sizes.xs * 1.5),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: sizes.icon(sizes.md),
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(ColorScheme colorScheme, AppSizesTheme sizes) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: sizes.icon(sizes.xxl),
        color: colorScheme.primary,
      ),
    );
  }
}

class _ActiveFamilyLinksSection extends ConsumerWidget {
  const _ActiveFamilyLinksSection({required this.onUnlink});

  final ValueChanged<ActiveFamilyLink> onUnlink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sizes = context.appSizes;
    final familiesState = ref.watch(activeFamilyLinksProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: sizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Familiares vinculados', style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.sm),
          familiesState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(
              'Não foi possível carregar os familiares vinculados.',
              style: theme.textTheme.bodySmall,
            ),
            data: (families) {
              if (families.isEmpty) {
                return Text(
                  'Nenhum familiar vinculado ainda.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }

              return Column(
                children: [
                  for (final family in families)
                    Padding(
                      padding: EdgeInsets.only(bottom: sizes.sm),
                      child: InfoCardWidget(
                        size: InfoCardSize.small,
                        borderRadius: BorderRadius.circular(sizes.radiusMd),
                        leading: CircleAvatar(
                          foregroundImage: profileImageProvider(
                            family.photoUrl,
                          ),
                          child: const Icon(Icons.person_rounded),
                        ),
                        content: Text(
                          family.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        trailing: IconButton(
                          tooltip: 'Desvincular familiar',
                          onPressed: () => onUnlink(family),
                          icon: const Icon(Icons.link_off_rounded),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Pedidos de vínculo de familiares aguardando resposta do idoso.
/// Só aparece quando existe pelo menos um pedido.
class _FamilyRequestsSection extends ConsumerWidget {
  const _FamilyRequestsSection();

  Future<void> _respond(
    BuildContext context,
    FamilyLinkRequest request, {
    required bool accept,
  }) async {
    final confirmed = await showConfirmModal(
      context,
      title: accept ? 'Aceitar familiar?' : 'Recusar pedido?',
      message: accept
          ? '${request.name} poderá acompanhar sua rotina e conversar com você.'
          : '${request.name} não será vinculado(a) a você.',
      confirmLabel: accept ? 'Aceitar' : 'Recusar',
    );

    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await AuthService.instance.respondToFamilyLinkRequest(
        linkId: request.linkId,
        accept: accept,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? '${request.name} agora está vinculado(a) a você.'
                : 'Pedido recusado.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível responder ao pedido. Tente novamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingFamilyRequestsProvider).asData?.value;
    if (requests == null || requests.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.only(bottom: sizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pedidos de familiares', style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.sm),
          for (final request in requests)
            Container(
              margin: EdgeInsets.only(bottom: sizes.sm),
              padding: EdgeInsets.all(sizes.md),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(sizes.radiusMd),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: .45),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: .14,
                        ),
                        foregroundImage: profileImageProvider(request.photoUrl),
                        child: Icon(
                          Icons.person_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: sizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              'quer se vincular a você',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: ButtonWidget(
                          label: 'Recusar',
                          size: ButtonSize.small,
                          variant: ButtonVariant.outlined,
                          onPressed: () =>
                              _respond(context, request, accept: false),
                        ),
                      ),
                      SizedBox(width: sizes.sm),
                      Expanded(
                        child: ButtonWidget(
                          label: 'Aceitar',
                          size: ButtonSize.small,
                          variant: ButtonVariant.secondary,
                          onPressed: () =>
                              _respond(context, request, accept: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecoveryContactsSection extends StatefulWidget {
  const _RecoveryContactsSection();

  @override
  State<_RecoveryContactsSection> createState() =>
      _RecoveryContactsSectionState();
}

class _RecoveryContactsSectionState extends State<_RecoveryContactsSection> {
  RecoveryContactsConfiguration? _configuration;
  String? _familyUid;
  String? _caregiverUid;
  Object? _loadError;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final configuration = await RecoveryContactsRepository.instance.load();
      if (!mounted) return;

      setState(() {
        _configuration = configuration;
        _familyUid = configuration.familyUid;
        _caregiverUid = configuration.caregiverUid;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final familyUid = _familyUid;
    final caregiverUid = _caregiverUid;
    if (_isSaving || familyUid == null || caregiverUid == null) return;

    setState(() {
      _isSaving = true;
      _hasSaved = false;
    });

    try {
      await RecoveryContactsRepository.instance.save(
        familyUid: familyUid,
        caregiverUid: caregiverUid,
      );
      if (!mounted) return;
      setState(() => _hasSaved = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
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
    final configuration = _configuration;
    return Container(
      padding: EdgeInsets.all(sizes.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Escolha um familiar e um cuidador. '
            'Qualquer um deles poderá aprovar um pedido de recuperação.',
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: sizes.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_loadError != null)
            Column(
              children: [
                Text(
                  'Não foi possível carregar os responsáveis disponíveis.',
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: _load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            )
          else if (configuration == null)
            const SizedBox.shrink()
          else if (configuration.families.isEmpty ||
              configuration.caregivers.isEmpty)
            Text(
              configuration.families.isEmpty
                  ? 'É necessário ter um familiar com vínculo ativo.'
                  : 'Não há cuidador ativo disponível nesta instituição.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue:
                  configuration.families.any(
                    (contact) => contact.uid == _familyUid,
                  )
                  ? _familyUid
                  : null,
              decoration: const InputDecoration(
                labelText: 'Familiar responsável',
              ),
              items: [
                for (final contact in configuration.families)
                  DropdownMenuItem(
                    value: contact.uid,
                    child: Text(contact.name),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (uid) => setState(() {
                      _familyUid = uid;
                      _hasSaved = false;
                    }),
            ),
            SizedBox(height: sizes.md),
            DropdownButtonFormField<String>(
              initialValue:
                  configuration.caregivers.any(
                    (contact) => contact.uid == _caregiverUid,
                  )
                  ? _caregiverUid
                  : null,
              decoration: const InputDecoration(
                labelText: 'Cuidador responsável',
              ),
              items: [
                for (final contact in configuration.caregivers)
                  DropdownMenuItem(
                    value: contact.uid,
                    child: Text(contact.name),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (uid) => setState(() {
                      _caregiverUid = uid;
                      _hasSaved = false;
                    }),
            ),
            SizedBox(height: sizes.md),
            ButtonWidget(
              label: _isSaving ? 'Salvando...' : 'Salvar responsáveis',
              variant: ButtonVariant.primary,
              onPressed:
                  _isSaving || _familyUid == null || _caregiverUid == null
                  ? null
                  : _save,
            ),
            if (_hasSaved) ...[
              SizedBox(height: sizes.sm),
              Text(
                'Responsáveis salvos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Mostra o código do idoso só depois de confirmar a senha, e esconde de
/// novo sozinho depois de alguns segundos.
class _AccessCodeCard extends StatefulWidget {
  const _AccessCodeCard({required this.code});

  final String? code;

  @override
  State<_AccessCodeCard> createState() => _AccessCodeCardState();
}

class _AccessCodeCardState extends State<_AccessCodeCard> {
  static const _visibleFor = Duration(seconds: 30);

  Timer? _hideTimer;
  bool _revealed = false;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _reveal() async {
    final confirmed = await showAppModal<bool>(
      context: context,
      title: 'Confirme sua senha',
      size: AppModalSize.small,
      child: const _PasswordPrompt(),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _revealed = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(_visibleFor, _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted) setState(() => _revealed = false);
  }

  Future<void> _copy(String code) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final code = widget.code?.trim() ?? '';

    final Widget content;

    if (code.isEmpty) {
      content = Text(
        'Código indisponível no momento.',
        style: theme.textTheme.bodyMedium,
      );
    } else if (_revealed) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            code,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              letterSpacing: 3,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: sizes.xs),
          Text(
            'O código some sozinho em 30 segundos.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: sizes.md),
          Row(
            children: [
              Expanded(
                child: ButtonWidget(
                  label: 'Ocultar',
                  size: ButtonSize.small,
                  variant: ButtonVariant.outlined,
                  onPressed: _hide,
                ),
              ),
              SizedBox(width: sizes.sm),
              Expanded(
                child: ButtonWidget(
                  label: 'Copiar',
                  size: ButtonSize.small,
                  variant: ButtonVariant.secondary,
                  onPressed: () => _copy(code),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '••••••',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 4),
          ),
          SizedBox(height: sizes.xs),
          Text(
            'É o código que seus familiares usam para se vincular a você. '
            'Digite sua senha para ver.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: sizes.md),
          ButtonWidget(
            label: 'Mostrar código',
            size: ButtonSize.small,
            variant: ButtonVariant.secondary,
            onPressed: _reveal,
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(sizes.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _PasswordPrompt extends StatefulWidget {
  const _PasswordPrompt();

  @override
  State<_PasswordPrompt> createState() => _PasswordPromptState();
}

class _PasswordPromptState extends State<_PasswordPrompt> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isChecking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isChecking) return;

    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Digite sua senha.');
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.verifyCurrentPassword(password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Por segurança, digite a senha que você usa para entrar.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        SizedBox(height: sizes.lg),
        TextFieldWidget(
          controller: _passwordController,
          hintText: 'Senha',
          obscureText: _obscure,
          enabled: !_isChecking,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _confirm(),
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: sizes.icon(sizes.lg),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: sizes.sm),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
        SizedBox(height: sizes.xl),
        ButtonWidget(
          label: _isChecking ? 'Confirmando...' : 'Confirmar',
          variant: ButtonVariant.secondary,
          onPressed: _isChecking ? null : _confirm,
        ),
        SizedBox(height: sizes.md),
        ButtonWidget(
          label: 'Cancelar',
          onPressed: _isChecking
              ? null
              : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
