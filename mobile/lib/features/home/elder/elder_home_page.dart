import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/action_card_widget.dart';
import '../../../shared/widgets/app_modal_widget.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../widgets/home_header_widget.dart';
import '../../../shared/widgets/info_card_widget.dart';
import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../chat/models/conversation_preview.dart';
import '../../chat/providers/conversation_previews_provider.dart';
import '../../routine/providers/next_elder_routine_provider.dart';
import '../widgets/next_task_card.dart';

class ElderHomePage extends ConsumerWidget {
  const ElderHomePage({super.key});

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  IconData _participantIcon(ConversationParticipantType participantType) {
    return switch (participantType) {
      ConversationParticipantType.family => Icons.family_restroom_rounded,
      ConversationParticipantType.caregiver => Icons.health_and_safety_rounded,
      ConversationParticipantType.elder => Icons.elderly_rounded,
      ConversationParticipantType.staff => Icons.badge_rounded,
    };
  }

  Widget _conversationAvatar(
    BuildContext context,
    ConversationPreview conversation,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final normalizedPhotoUrl = conversation.photoUrl?.trim();
    final hasPhoto =
        normalizedPhotoUrl != null && normalizedPhotoUrl.isNotEmpty;

    return CircleAvatar(
      backgroundColor: colorScheme.primary.withValues(alpha: .12),
      foregroundImage: hasPhoto ? NetworkImage(normalizedPhotoUrl) : null,
      child: Icon(
        _participantIcon(conversation.participantType),
        color: colorScheme.primary,
        size: sizes.md,
      ),
    );
  }

  Widget _emptyMessage(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.lg),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: sizes.xl),
          SizedBox(height: sizes.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatPreview(
    BuildContext context,
    AsyncValue<List<ConversationPreview>> conversationsState,
    AsyncValue<Set<String>> linkedFamilyIdsState,
  ) {
    final sizes = context.appSizes;

    return conversationsState.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.lg),
        child: const CircularProgressIndicator(),
      ),
      error: (_, _) => _emptyMessage(
        context,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível carregar as conversas.',
      ),
      data: (conversations) {
        final linkedFamilyIds = linkedFamilyIdsState.asData?.value;
        final visibleConversations = conversations
            .where((conversation) {
              if (conversation.participantType !=
                  ConversationParticipantType.family) {
                return true;
              }
              return linkedFamilyIds != null &&
                  linkedFamilyIds.contains(conversation.participantId);
            })
            .take(2)
            .toList();

        if (visibleConversations.isEmpty) {
          return _emptyMessage(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            message: 'Você ainda não possui conversas.',
          );
        }

        return Column(
          children: [
            for (
              var index = 0;
              index < visibleConversations.length;
              index++
            ) ...[
              InfoCardWidget(
                leading: _conversationAvatar(
                  context,
                  visibleConversations[index],
                ),
                title: visibleConversations[index].participantName,
                subtitle: visibleConversations[index].lastMessage,
                size: InfoCardSize.small,
                showGotoButton: true,
                onPressed: () => context.go(
                  RouteNames.chatConversationPath(
                    visibleConversations[index].id,
                  ),
                ),
              ),
              if (index < visibleConversations.length - 1)
                SizedBox(height: sizes.lg),
            ],
            SizedBox(height: sizes.sm),
            TextButton(
              onPressed: () => context.go(RouteNames.chat),
              child: const Text('Ver mais'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNotifications(BuildContext context) async {
    await showAppModal<void>(
      context: context,
      title: 'Notificações',
      size: AppModalSize.medium,
      child: _emptyMessage(
        context,
        icon: Icons.notifications_none_rounded,
        message: 'Você não possui notificações no momento.',
      ),
    );
  }

  void _showUnavailableMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _homeContent(
    BuildContext context,
    WidgetRef ref,
    UserSession session,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = context.appGradientColors;
    final sizes = context.appSizes;
    final nextRoutine = ref.watch(nextElderRoutineProvider);
    final conversations = ref.watch(conversationPreviewsProvider);
    final linkedFamilyIds = ref.watch(linkedFamilyIdsProvider);
    final displayName = session.name.trim().isEmpty
        ? 'Usuário'
        : session.name.trim();

    Widget actionIllustration() {
      return Icon(
        Icons.report_rounded,
        size: sizes.xxl * 2,
        color: colorScheme.onPrimary,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientColors.bottom, gradientColors.top],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              HomeHeaderWidget(
                name: displayName,
                greeting: 'Bem-vinda,',
                photoUrl: session.photoUrl,
                notificationCount: 0,
                onNotificationsPressed: () async {
                  await _openNotifications(context);
                },
              ),
              ContentPanelWidget(
                topPanelPadding: EdgeInsets.fromLTRB(
                  sizes.lg,
                  sizes.lg,
                  sizes.lg,
                  sizes.xl,
                ),
                topPanel: nextRoutine.when(
                  loading: () =>
                      const NextTaskCard(task: null, isLoading: true),
                  error: (_, _) => const NextTaskCard(
                    task: null,
                    emptyMessage: 'Não foi possível carregar a próxima tarefa',
                  ),
                  data: (task) => NextTaskCard(
                    task: task,
                    onPressed: task == null
                        ? null
                        : () => context.go(RouteNames.routine),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  sizes.lg,
                  sizes.xl + sizes.sm,
                  sizes.lg,
                  sizes.xxl,
                ),
                child: Column(
                  children: [
                    _sectionTitle(context, 'Chat - Converse'),
                    SizedBox(height: sizes.md),
                    _chatPreview(context, conversations, linkedFamilyIds),
                    SizedBox(height: sizes.xxl),
                    _sectionTitle(
                      context,
                      'Assistente Virtual  -\nTire Dúvidas',
                    ),
                    SizedBox(height: sizes.md),
                    ActionCardWidget(
                      title: 'Tire dúvidas sobre\ntecnologia com o Auri',
                      imageAsset: AssetPaths.auri,
                      illustrationSize: sizes.xxl * 2.5,
                      imageSemanticLabel: 'Assistente virtual Auri',
                      actionLabel: 'Comece agora!',
                      onPressed: () {
                        _showUnavailableMessage(
                          context,
                          'O assistente virtual será disponibilizado em breve.',
                        );
                      },
                    ),
                    SizedBox(height: sizes.xxl),
                    _sectionTitle(context, 'Central de Denúncias  -\nDenuncie'),
                    SizedBox(height: sizes.md),
                    ActionCardWidget(
                      title:
                          'Denuncie abusos que\nestiver sofrendo de\n'
                          'maneira anônima',
                      illustration: actionIllustration(),
                      illustrationSize: sizes.xxl * 2,
                      actionLabel: 'Denuncie!',
                      onPressed: () {
                        _showUnavailableMessage(
                          context,
                          'A central de denúncias será disponibilizada em breve.',
                        );
                      },
                      layout: ActionCardLayout.textFirst,
                      showIllustrationBackground: false,
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes.xxl * 2 + sizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionState(
    BuildContext context, {
    required IconData icon,
    required String message,
    bool loading = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(sizes.lg),
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: sizes.xxl, color: colorScheme.primary),
                    SizedBox(height: sizes.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      extendBody: true,
      body: currentUser.when(
        loading: () => _sessionState(
          context,
          icon: Icons.person_rounded,
          message: '',
          loading: true,
        ),
        error: (error, _) => _sessionState(
          context,
          icon: Icons.error_outline_rounded,
          message: error.toString().replaceFirst('Bad state: ', ''),
        ),
        data: (session) {
          if (session == null) {
            return _sessionState(
              context,
              icon: Icons.person_off_rounded,
              message: 'Usuário não autenticado.',
            );
          }

          if (session.accountType != AccountType.elder) {
            return _sessionState(
              context,
              icon: Icons.lock_person_rounded,
              message: 'Esta página é exclusiva para a conta do idoso.',
            );
          }

          return _homeContent(context, ref, session);
        },
      ),
    );
  }
}
