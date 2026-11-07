import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/utils/profile_image.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/info_card_widget.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../chat/models/conversation_preview.dart';
import '../../chat/providers/conversation_previews_provider.dart';
import '../../chat/widgets/chat_avatar_widget.dart';
import '../../routine/models/routine_elder_summary.dart';
import '../../routine/models/routine_task.dart';
import '../../routine/models/routine_task_completion.dart';
import '../../routine/providers/routine_provider.dart';
import '../widgets/home_header_widget.dart';

typedef _PendingRoutineTask = ({RoutineElderSummary elder, RoutineTask task});

class CaregiverHomePage extends ConsumerStatefulWidget {
  const CaregiverHomePage({super.key, this.caregiverData = const {}});

  final Map<String, dynamic> caregiverData;

  @override
  ConsumerState<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends ConsumerState<CaregiverHomePage> {
  late DateTime _now;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = context.appGradientColors;
    final sizes = context.appSizes;
    final sessionState = ref.watch(currentUserProvider);
    final session = sessionState.hasValue ? sessionState.requireValue : null;
    final sessionName = session?.name.trim() ?? '';
    final providedName = widget.caregiverData['name']?.toString().trim() ?? '';
    final name = sessionName.isNotEmpty
        ? sessionName
        : providedName.isNotEmpty
        ? providedName
        : 'Cuidador';
    final photoUrl =
        session?.photoUrl ?? widget.caregiverData['photoUrl']?.toString();
    final elders = ref.watch(accessibleRoutineEldersProvider);
    final conversations = ref.watch(conversationPreviewsProvider);
    final elderItems = elders.hasValue
        ? elders.requireValue
        : const <RoutineElderSummary>[];
    final taskStates = [
      for (final elder in elderItems) ref.watch(routineTasksProvider(elder.id)),
    ];
    final completionStates = [
      for (final elder in elderItems)
        ref.watch(routineCompletionsProvider(elder.id)),
    ];
    final routineError =
        elders.hasError ||
        taskStates.any((state) => state.hasError) ||
        completionStates.any((state) => state.hasError);
    final pendingTasks =
        routineError ||
            !elders.hasValue ||
            taskStates.any((state) => !state.hasValue) ||
            completionStates.any((state) => !state.hasValue)
        ? null
        : _findPendingRoutineTasks(
            elders: elderItems,
            taskStates: taskStates,
            completionStates: completionStates,
            now: _now,
          );
    final residentsSubtitle = elders.when(
      data: (items) => items.length == 1
          ? '1 pessoa sob cuidado'
          : '${items.length} pessoas sob cuidado',
      loading: () => 'Carregando residentes...',
      error: (_, _) => 'Não foi possível carregar os residentes',
    );
    final attentionSubtitle = pendingTasks == null
        ? 'Requer sua atenção'
        : pendingTasks.length == 1
        ? '1 pendência'
        : '${pendingTasks.length} pendências';

    return Scaffold(
      body: DecoratedBox(
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
                  name: name,
                  photoUrl: photoUrl,
                  subtitle: '$residentsSubtitle\n$attentionSubtitle',
                ),
                ContentPanelWidget(
                  topPanelPadding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.lg,
                    sizes.lg,
                    sizes.xl,
                  ),
                  topPanel: _PendingRoutineAttention(
                    pendingTasks: pendingTasks,
                    hasError: routineError,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.xl + sizes.sm,
                    sizes.lg,
                    sizes.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Chat - Converse'),
                      SizedBox(height: sizes.md),
                      _conversationContent(context, conversations),
                      SizedBox(height: sizes.xl),
                      _sectionTitle(context, 'Residentes sob cuidado'),
                      SizedBox(height: sizes.sm),
                      _residentContent(context, elders),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _conversationContent(
    BuildContext context,
    AsyncValue<List<ConversationPreview>> conversations,
  ) {
    return conversations.when(
      data: (items) {
        final recent = items.take(3).toList();
        if (recent.isEmpty) {
          return _emptyState(context, 'Você ainda não possui conversas.');
        }

        return Column(
          children: [
            for (var index = 0; index < recent.length; index++) ...[
              _conversationCard(context, recent[index]),
              if (index < recent.length - 1)
                SizedBox(height: context.appSizes.sm),
            ],
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => context.go(RouteNames.chat),
                child: const Text('Ver todas'),
              ),
            ),
          ],
        );
      },
      loading: () => _loadingState(context),
      error: (_, _) => _errorState(context, 'conversas'),
    );
  }

  Widget _conversationCard(
    BuildContext context,
    ConversationPreview conversation,
  ) {
    final subtitle = conversation.lastMessage.trim().isEmpty
        ? 'Toque para iniciar uma conversa'
        : conversation.lastMessage;

    return InfoCardWidget(
      leading: ChatAvatarWidget(
        participantType: conversation.participantType,
        photoUrl: conversation.photoUrl,
        unreadCount: conversation.unreadCount,
        size: context.appSizes.buttonSmall * .75 - context.appSizes.xs,
      ),
      title: conversation.participantName,
      subtitle: subtitle,
      size: InfoCardSize.small,
      showGotoButton: true,
      onPressed: () =>
          context.go(RouteNames.chatConversationPath(conversation.id)),
    );
  }

  Widget _residentContent(
    BuildContext context,
    AsyncValue<List<RoutineElderSummary>> elders,
  ) {
    return elders.when(
      data: (items) {
        final visibleElders = items.take(4).toList();
        if (visibleElders.isEmpty) {
          return _emptyState(context, 'Nenhum residente vinculado.');
        }

        return Column(
          children: [
            for (final elder in visibleElders) _residentRow(context, elder),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => context.go(RouteNames.routine),
                child: const Text('Ver todos'),
              ),
            ),
          ],
        );
      },
      loading: () => _loadingState(context),
      error: (_, _) => _errorState(context, 'residentes'),
    );
  }

  Widget _residentRow(BuildContext context, RoutineElderSummary elder) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final photoUrl = elder.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(sizes.radiusFull),
          onTap: () => context.go(RouteNames.routinePath(elder.id)),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: sizes.xs),
            child: Row(
              children: [
                CircleAvatar(
                  radius: sizes.lg,
                  backgroundColor: colorScheme.primary.withValues(alpha: .12),
                  foregroundImage: hasPhoto
                      ? profileImageProvider(photoUrl)
                      : null,
                  child: hasPhoto
                      ? null
                      : Icon(
                          Icons.elderly_rounded,
                          color: colorScheme.primary,
                          size: sizes.md,
                        ),
                ),
                SizedBox(width: sizes.md),
                Expanded(
                  child: Text(
                    elder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.md),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _loadingState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.appSizes.md),
      child: const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, String content) {
    return _emptyState(
      context,
      'Não foi possível carregar $content. Tente novamente mais tarde.',
    );
  }
}

class _PendingRoutineAttention extends StatelessWidget {
  const _PendingRoutineAttention({
    required this.pendingTasks,
    required this.hasError,
  });

  final List<_PendingRoutineTask>? pendingTasks;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    if (hasError) {
      return _attentionSection(
        context,
        title: 'Requer sua atenção',
        content: Text(
          'Não foi possível carregar as tarefas da rotina.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (pendingTasks == null) {
      return _attentionSection(
        context,
        title: 'Requer sua atenção',
        content: const Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final visibleTasks = pendingTasks!.take(3).toList();
    final taskList = pendingTasks!.isEmpty
        ? Text(
            'Nenhuma tarefa requer atenção neste momento.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        : Column(
            children: [
              for (var index = 0; index < visibleTasks.length; index++) ...[
                InfoCardWidget(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withValues(alpha: .12),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: colorScheme.primary,
                      size: sizes.md,
                    ),
                  ),
                  title: visibleTasks[index].task.title,
                  subtitle:
                      '${visibleTasks[index].elder.name} · '
                      '${visibleTasks[index].task.timeLabel}',
                  size: InfoCardSize.small,
                  showGotoButton: true,
                  onPressed: () => context.go(
                    RouteNames.routinePath(visibleTasks[index].elder.id),
                  ),
                ),
                if (index < visibleTasks.length - 1) SizedBox(height: sizes.sm),
              ],
              if (pendingTasks!.length > visibleTasks.length)
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.routine),
                    child: const Text('Ver todas'),
                  ),
                ),
            ],
          );

    return _attentionSection(
      context,
      title: 'Requer sua atenção',
      count: pendingTasks!.length,
      content: taskList,
    );
  }

  Widget _attentionSection(
    BuildContext context, {
    required String title,
    required Widget content,
    int count = 0,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (count > 0)
              Container(
                constraints: BoxConstraints(minWidth: sizes.lg),
                padding: EdgeInsets.symmetric(
                  horizontal: sizes.xs,
                  vertical: sizes.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(sizes.radiusFull),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: sizes.md),
        content,
      ],
    );
  }
}

List<_PendingRoutineTask> _findPendingRoutineTasks({
  required List<RoutineElderSummary> elders,
  required List<AsyncValue<List<RoutineTask>>> taskStates,
  required List<AsyncValue<List<RoutineTaskCompletion>>> completionStates,
  required DateTime now,
}) {
  final today = RoutineTask.dateOnly(now);
  final pendingTasks = <_PendingRoutineTask>[];

  for (var index = 0; index < elders.length; index++) {
    final elder = elders[index];
    final completedIds = completionStates[index].requireValue
        .map((completion) => completion.id)
        .toSet();

    for (final task in taskStates[index].requireValue) {
      if (!task.occursOn(today) || task.startOn(today).isAfter(now)) {
        continue;
      }

      final completionId = RoutineTaskCompletion.documentIdFor(
        taskId: task.id,
        occurrenceDate: today,
        taskWasRecurring: task.repeatWeekly,
      );
      if (!completedIds.contains(completionId)) {
        pendingTasks.add((elder: elder, task: task));
      }
    }
  }

  pendingTasks.sort(
    (first, second) =>
        first.task.startOn(today).compareTo(second.task.startOn(today)),
  );
  return pendingTasks;
}
