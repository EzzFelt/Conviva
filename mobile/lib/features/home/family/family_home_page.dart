import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/utils/profile_image.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../chat/models/conversation_preview.dart';
import '../../chat/providers/conversation_previews_provider.dart';
import '../../routine/models/routine_elder_summary.dart';
import '../../routine/models/routine_task.dart';
import '../../routine/providers/routine_provider.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/routine_task_icon.dart';

class FamilyHomePage extends ConsumerWidget {
  const FamilyHomePage({super.key, this.elderId, this.elderName = 'Idoso'});

  final String? elderId;
  final String elderName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradientColors = context.appGradientColors;
    final sizes = context.appSizes;
    final sessionState = ref.watch(currentUserProvider);
    final session = sessionState.hasValue ? sessionState.requireValue : null;
    final familyName = session?.name.trim();
    final displayName = familyName == null || familyName.isEmpty
        ? 'Usuário'
        : familyName;
    final eldersState = ref.watch(accessibleRoutineEldersProvider);
    final linkedElderIdsState = ref.watch(linkedFamilyIdsProvider);
    final conversationsState = ref.watch(conversationPreviewsProvider);
    final elders = eldersState.hasValue
        ? eldersState.requireValue
        : const <RoutineElderSummary>[];
    final elder =
        elders.where((item) => item.id == elderId).firstOrNull ??
        (elderId == null && elders.isNotEmpty ? elders.first : null);
    final resolvedElderId = elder?.id ?? elderId;
    final routineState = resolvedElderId == null
        ? null
        : ref.watch(routineTasksProvider(resolvedElderId));
    final linkedElderIds = linkedElderIdsState.hasValue
        ? linkedElderIdsState.requireValue
        : elderId != null
        ? {elderId!}
        : elders.map((item) => item.id).toSet();
    final conversations = conversationsState.hasValue
        ? conversationsState.requireValue
        : const <ConversationPreview>[];
    final familyConversations = conversations
        .where(
          (conversation) =>
              conversation.participantType ==
                  ConversationParticipantType.elder &&
              linkedElderIds.contains(conversation.participantId),
        )
        .toList();
    final isConversationLoading =
        !conversationsState.hasValue ||
        (!linkedElderIdsState.hasValue && elderId == null);
    final conversationError =
        (conversationsState.hasError && !conversationsState.hasValue) ||
        (linkedElderIdsState.hasError && !linkedElderIdsState.hasValue);
    final latestConversation = familyConversations.isEmpty
        ? null
        : familyConversations.first;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 200 || constraints.maxHeight < 200) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                HomeHeaderWidget(
                  name: displayName,
                  greeting: 'Olá,',
                  photoUrl: session?.photoUrl,
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(sizes.radiusLg + sizes.sm),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        sizes.lg,
                        sizes.lg,
                        sizes.lg,
                        MediaQuery.paddingOf(context).bottom + sizes.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _routineSummary(
                            context,
                            elder: elder,
                            elderId: resolvedElderId,
                            elderNameFallback: elderName,
                            eldersState: eldersState,
                            tasksState: routineState,
                          ),
                          SizedBox(height: sizes.lg),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                gradientColors.bottom,
                                gradientColors.top,
                              ],
                            ).createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              'Converse com seu\nparente',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                          ),
                          SizedBox(height: sizes.md),
                          _latestMessage(
                            context,
                            conversation: latestConversation,
                            isLoading: isConversationLoading,
                            hasError: conversationError,
                            elder: elder,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _routineSummary(
    BuildContext context, {
    required RoutineElderSummary? elder,
    required String? elderId,
    required String elderNameFallback,
    required AsyncValue<List<RoutineElderSummary>> eldersState,
    required AsyncValue<List<RoutineTask>>? tasksState,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final elderPhoto = profileImageProvider(elder?.photoUrl);

    void openRoutine() {
      if (elderId == null) {
        if (!eldersState.isLoading && !eldersState.hasError) {
          context.go(RouteNames.routine);
        }
        return;
      }

      context.go(RouteNames.routinePath(elderId));
    }

    return Padding(
      padding: EdgeInsets.only(bottom: sizes.md),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            key: const ValueKey('family-routine-card'),
            color: colorScheme.surface,
            elevation: sizes.xs,
            shadowColor: colorScheme.shadow.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(sizes.radiusMd),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(sizes.md),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(sizes.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: sizes.lg,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: .12,
                        ),
                        foregroundImage: elderPhoto,
                        child: elderPhoto == null
                            ? Icon(
                                Icons.person_rounded,
                                color: colorScheme.primary,
                              )
                            : null,
                      ),
                      SizedBox(width: sizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              elder?.name ??
                                  (elderNameFallback == 'Idoso'
                                      ? 'Seu parente'
                                      : elderNameFallback),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Mais importantes hoje:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sizes.md),
                  _todaySchedule(context, tasksState, eldersState),
                  SizedBox(height: sizes.md),
                ],
              ),
            ),
          ),
          Positioned(
            right: -sizes.sm,
            bottom: -sizes.sm,
            child: ElevatedButton(
              onPressed:
                  elderId == null &&
                      (eldersState.isLoading || eldersState.hasError)
                  ? null
                  : openRoutine,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: sizes.lg,
                  vertical: sizes.sm + sizes.xs,
                ),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(sizes.radiusFull),
                ),
              ),
              child: const Text('Ver rotina completa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _todaySchedule(
    BuildContext context,
    AsyncValue<List<RoutineTask>>? tasksState,
    AsyncValue<List<RoutineElderSummary>> eldersState,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    if (tasksState == null) {
      if (eldersState.isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      if (eldersState.hasError) {
        return _scheduleMessage(
          context,
          'Não foi possível carregar os dados do seu parente.',
        );
      }

      return _scheduleMessage(
        context,
        'Vincule seu parente para consultar a rotina.',
      );
    }

    return tasksState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) =>
          _scheduleMessage(context, 'Não foi possível carregar a rotina.'),
      data: (tasks) {
        final now = DateTime.now();
        final today = RoutineTask.dateOnly(now);
        final todayTasks = tasks.where((task) => task.occursOn(today)).toList()
          ..sort(
            (first, second) =>
                first.startOn(today).compareTo(second.startOn(today)),
          );
        final visibleTasks = todayTasks.take(3).toList();

        if (visibleTasks.isEmpty) {
          return _scheduleMessage(
            context,
            'Nenhuma atividade programada para hoje.',
          );
        }

        return Row(
          children: [
            for (var index = 0; index < visibleTasks.length; index++) ...[
              if (index > 0) SizedBox(width: sizes.sm),
              Expanded(
                child: Container(
                  key: ValueKey('family-task-${visibleTasks[index].id}'),
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: EdgeInsets.symmetric(
                    horizontal: sizes.xs,
                    vertical: sizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: .6),
                    ),
                    borderRadius: BorderRadius.circular(sizes.radiusMd),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(sizes.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4E4C5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          routineTaskIcon(visibleTasks[index].type),
                          color: colorScheme.primary,
                          size: sizes.lg,
                        ),
                      ),
                      SizedBox(height: sizes.sm),
                      Text(
                        visibleTasks[index].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: sizes.xs),
                      Text(
                        _formatTime(visibleTasks[index].startOn(today)),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _latestMessage(
    BuildContext context, {
    required ConversationPreview? conversation,
    required bool isLoading,
    required bool hasError,
    required RoutineElderSummary? elder,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (hasError) {
      return _scheduleMessage(
        context,
        'Não foi possível carregar as mensagens.',
      );
    }

    final avatar = elder == null ? null : profileImageProvider(elder.photoUrl);
    final lastMessage = conversation == null
        ? 'Inicie uma conversa com seu parente.'
        : conversation.lastMessage.trim().isEmpty
        ? 'Inicie uma conversa'
        : conversation.lastMessage;
    final timeLabel = conversation?.lastMessageAt == null
        ? ''
        : _formatTime(conversation!.lastMessageAt!);

    final cardRadius = BorderRadius.circular(sizes.radiusMd);
    void openConversation() {
      context.go(
        conversation == null
            ? RouteNames.chat
            : RouteNames.chatConversationPath(conversation.id),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: sizes.md, right: sizes.sm),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            borderRadius: cardRadius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomLeft,
                  colors: [
                    context.appGradientColors.top,
                    context.appGradientColors.bottom,
                  ],
                ),
                borderRadius: cardRadius,
              ),
              child: InkWell(
                onTap: openConversation,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    sizes.md,
                    sizes.md,
                    sizes.md + sizes.xs,
                    sizes.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Última mensagem',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: sizes.sm),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorScheme.surface,
                            foregroundImage: avatar,
                            child: avatar == null
                                ? Icon(
                                    Icons.person_rounded,
                                    color: colorScheme.primary,
                                  )
                                : null,
                          ),
                          SizedBox(width: sizes.sm),
                          Expanded(
                            child: Container(
                              key: const ValueKey('family-message-bubble'),
                              padding: EdgeInsets.all(sizes.sm),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: .35,
                                  ),
                                ),
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  sizes.radiusSm,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withValues(
                                      alpha: .16,
                                    ),
                                    blurRadius: sizes.xs,
                                    offset: Offset(0, sizes.xs / 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lastMessage,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  if (timeLabel.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(right: sizes.lg),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          timeLabel,
                                          key: const ValueKey(
                                            'family-message-time',
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -sizes.sm,
            bottom: -sizes.xs,
            child: Material(
              key: const ValueKey('family-message-send-button'),
              color: colorScheme.primary,
              shape: const CircleBorder(),
              elevation: sizes.xs,
              child: InkWell(
                onTap: openConversation,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(sizes.xs),
                  child: SizedBox.square(
                    dimension: sizes.xxl,
                    child: Icon(
                      Icons.send_rounded,
                      key: const ValueKey('family-message-send-icon'),
                      color: colorScheme.onPrimary,
                      size: sizes.lg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleMessage(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.appSizes.md),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}
