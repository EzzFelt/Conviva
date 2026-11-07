import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:conviva/shared/utils/profile_image.dart';

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
import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../routine/models/routine_elder_summary.dart';
import '../../routine/providers/routine_provider.dart';
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
    UserSession session,
  ) {
    return showAppModal<void>(
      context: context,
      size: AppModalSize.medium,
      child: _EditProfileForm(session: session),
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
  ) {
    final sizes = context.appSizes;
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
        if (elders.isEmpty) {
          return _sectionMessage(context, 'Nenhum parente vinculado ainda.');
        }

        return Column(
          children: [
            for (final elder in elders)
              Padding(
                padding: EdgeInsets.only(bottom: sizes.sm),
                child: _linkedElderCard(context, elder, institutionName),
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
        onPressed: () => _editProfile(context, session),
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
    final isFamily = session.accountType == AccountType.family;
    final phone = session.phone.isEmpty
        ? 'Não informado'
        : BrazilianPhoneFormatter.format(session.phone);
    final subtitle = isFamily
        ? (session.phone.isEmpty ? 'Parente' : '$phone - Parente')
        : phone;

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
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: sizes.lg),
          if (isFamily) ...[
            Text('Parentes Vinculados', style: theme.textTheme.titleMedium),
            SizedBox(height: sizes.sm),
            _linkedEldersSection(context, ref, institutionState),
          ] else ...[
            Text('Instituto', style: theme.textTheme.titleMedium),
            SizedBox(height: sizes.sm),
            _institutionCard(context, institutionState),
          ],
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
                    child: Center(child: _ProfileAvatar(session: session)),
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
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
    _phoneController = TextEditingController(
      text: BrazilianPhoneFormatter.format(widget.session.phone),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
      await ref.read(currentUserProvider.notifier).updateProfile(
            name: _nameController.text,
            phone: _phoneController.text,
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

  bool get _hasPhoto =>
      profileImageProvider(widget.session.photoUrl) != null;

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

        await notifier.updateProfilePhoto(
          bytes: bytes,
          extension: extension,
        );
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
                border: Border.all(color: colorScheme.surface, width: sizes.xs),
              ),
              child: CircleAvatar(
                radius: sizes.xxl,
                backgroundColor: colorScheme.primary.withValues(alpha: .14),
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
                            errorBuilder: (_, _, _) => _fallbackIcon(
                              colorScheme,
                              sizes,
                            ),
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
