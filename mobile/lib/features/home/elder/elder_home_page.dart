import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/action_card_widget.dart';
import '../../../shared/widgets/auri_avatar_widget.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../widgets/home_header_widget.dart';
import '../../../shared/widgets/info_card_widget.dart';
import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../chat/models/conversation_preview.dart';
import '../../chat/providers/conversation_previews_provider.dart';
import '../../chat/widgets/chat_avatar_widget.dart';
import '../../chat/widgets/conversation_card_content.dart';
import '../../chat/utils/conversation_preview_sorter.dart';
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

  Widget _conversationAvatar(
    BuildContext context,
    ConversationPreview conversation,
  ) {
    final sizes = context.appSizes;
    return ChatAvatarWidget(
      participantType: conversation.participantType,
      photoUrl: conversation.photoUrl,
      unreadCount: conversation.unreadCount,
      size: sizes.buttonSmall,
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
        final visibleConversations = sortConversationsByLatestMessage(
          conversations.where((conversation) {
            if (conversation.participantType !=
                ConversationParticipantType.family) {
              return true;
            }
            return linkedFamilyIds != null &&
                linkedFamilyIds.contains(conversation.participantId);
          }),
        ).take(3).toList();

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
                content: ConversationCardContent(
                  conversation: visibleConversations[index],
                  emptyMessage: 'Toque para conversar',
                  showTimestamp: false,
                ),
                size: InfoCardSize.small,
                trailing: ConversationCardTrailingWidget(
                  conversation: visibleConversations[index],
                  onPressed: () => context.go(
                    RouteNames.chatConversationPath(
                      visibleConversations[index].id,
                    ),
                  ),
                ),
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
              child: Text(
                'Ver todos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.appGradientColors.bottom,
                  decoration: TextDecoration.underline,
                  decorationColor: context.appGradientColors.bottom,
                ),
              ),
            ),
          ],
        );
      },
    );
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
    final bottomScrollPadding =
        sizes.lg +
        sizes.xxl +
        sizes.xl +
        sizes.sm +
        MediaQuery.viewPaddingOf(context).bottom +
        sizes.lg;
    final displayName = session.name.trim().isEmpty
        ? 'Usuário'
        : session.name.trim();

    Widget actionIllustration() {
      return Icon(
        Icons.feedback_rounded,
        size: sizes.icon(sizes.xxl * 2),
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeaderWidget(
                name: displayName,
                greeting: 'Olá,',
                photoUrl: session.photoUrl,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                key: const ValueKey('elder-home-next-task-panel'),
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  sizes.lg,
                  sizes.lg,
                  sizes.lg,
                  sizes.xl,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panelTop,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(sizes.radiusLg + sizes.sm),
                    topRight: Radius.circular(sizes.radiusLg + sizes.sm),
                  ),
                ),
                child: nextRoutine.when(
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
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: ColoredBox(
                color: AppColors.panelTop,
                child: ContentPanelWidget(
                  padding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.xl + sizes.sm,
                    sizes.lg,
                    bottomScrollPadding,
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
                        illustration: const AuriAvatarWidget(),
                        illustrationSize: sizes.xxl * 2.5,
                        actionLabel: 'Comece agora!',
                        onPressed: () {
                          context.go(RouteNames.auri);
                        },
                      ),
                      SizedBox(height: sizes.xxl),
                      _sectionTitle(
                        context,
                        'Central de Denúncias  -\nDenuncie',
                      ),
                      SizedBox(height: sizes.md),
                      ActionCardWidget(
                        title:
                            'Denuncie abusos que\nestiver sofrendo de\n'
                            'maneira anônima',
                        illustration: actionIllustration(),
                        illustrationSize: sizes.xxl * 2,
                        actionLabel: 'Denuncie!',
                        onPressed: () {
                          context.push(RouteNames.reportStart);
                        },
                        layout: ActionCardLayout.textFirst,
                        showIllustrationBackground: false,
                      ),
                      SizedBox(height: sizes.xxl * 2 + sizes.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionState(
    BuildContext context, {
    required IconData icon,
    required String message,
    bool loading = false,
    VoidCallback? onRetry,
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
                    Icon(
                      icon,
                      size: sizes.icon(sizes.xxl),
                      color: colorScheme.primary,
                    ),
                    SizedBox(height: sizes.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (onRetry != null)
                      Padding(
                        padding: EdgeInsets.only(top: sizes.md),
                        child: TextButton(
                          onPressed: onRetry,
                          child: Text('Tentar novamente'),
                        ),
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
        error: (_, _) => _sessionState(
          context,
          icon: Icons.error_outline_rounded,
          message:
              'Não foi possível carregar sua conta. '
              'Verifique sua conexão e tente novamente.',
          onRetry: () {
            ref.invalidate(currentUserProvider);
          },
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
