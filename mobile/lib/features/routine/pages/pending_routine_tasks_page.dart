import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/utils/profile_image.dart';
import '../../../shared/widgets/info_card_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../models/routine_elder_summary.dart';
import '../models/routine_task.dart';
import '../models/routine_task_completion.dart';
import '../providers/routine_provider.dart';
import '../utils/pending_routine_task_finder.dart';

class PendingRoutineTasksPage extends ConsumerWidget {
  const PendingRoutineTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eldersState = ref.watch(accessibleRoutineEldersProvider);
    final elders = eldersState.asData?.value;
    final taskStates = elders == null
        ? const <AsyncValue<List<RoutineTask>>>[]
        : [
            for (final elder in elders)
              ref.watch(routineTasksProvider(elder.id)),
          ];
    final completionStates = elders == null
        ? const <AsyncValue<List<RoutineTaskCompletion>>>[]
        : [
            for (final elder in elders)
              ref.watch(routineCompletionsProvider(elder.id)),
          ];

    final hasError =
        eldersState.hasError ||
        taskStates.any((state) => state.hasError) ||
        completionStates.any((state) => state.hasError);
    final isLoading =
        !eldersState.hasValue ||
        taskStates.any((state) => !state.hasValue) ||
        completionStates.any((state) => !state.hasValue);

    final Widget content;
    if (hasError) {
      content = const _PendingTasksMessage(
        message: 'Não foi possível carregar as pendências da rotina.',
      );
    } else if (isLoading) {
      content = const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      final loadedElders = elders!;
      final tasksByElder = [for (final state in taskStates) state.requireValue];
      final completionsByElder = [
        for (final state in completionStates) state.requireValue,
      ];
      final pendingTasks = findPendingRoutineTasks(
        elders: loadedElders,
        tasksByElder: tasksByElder,
        completionsByElder: completionsByElder,
        now: DateTime.now(),
      );
      final eldersWithoutTasks = [
        for (var index = 0; index < loadedElders.length; index++)
          if (tasksByElder[index].isEmpty) loadedElders[index],
      ];
      content = _pendingItems(
        context,
        pendingTasks: pendingTasks,
        eldersWithoutTasks: eldersWithoutTasks,
      );
    }

    final sizes = context.appSizes;
    final gradient = context.appGradientColors;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradient.bottom, gradient.top],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PageHeaderWidget(
                  title: 'Pendências',
                  onBackPressed: () => context.go(RouteNames.caregiverHome),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.lg,
                    sizes.lg,
                    sizes.xxl * 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(sizes.radiusLg + sizes.sm),
                      topRight: Radius.circular(sizes.radiusLg + sizes.sm),
                    ),
                  ),
                  child: content,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: ColoredBox(
                  key: const ValueKey('pending-page-bottom-surface'),
                  color: theme.colorScheme.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingItems(
    BuildContext context, {
    required List<PendingRoutineTask> pendingTasks,
    required List<RoutineElderSummary> eldersWithoutTasks,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final cards = <Widget>[
      for (final pending in pendingTasks)
        InfoCardWidget(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: .12),
            child: Icon(
              Icons.schedule_rounded,
              color: colorScheme.primary,
              size: sizes.icon(sizes.md),
            ),
          ),
          title: pending.task.title,
          subtitle: '${pending.elder.name} · ${pending.task.timeLabel}',
          size: InfoCardSize.small,
          showGotoButton: true,
          onPressed: () => context.go(RouteNames.routinePath(pending.elder.id)),
        ),
      for (final elder in eldersWithoutTasks)
        InfoCardWidget(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: .12),
            foregroundImage: elder.photoUrl == null
                ? null
                : profileImageProvider(elder.photoUrl),
            child: elder.photoUrl == null
                ? Icon(
                    Icons.elderly_rounded,
                    color: colorScheme.primary,
                    size: sizes.icon(sizes.md),
                  )
                : null,
          ),
          title: elder.name,
          subtitle: 'Não possui tarefas na rotina.',
          size: InfoCardSize.small,
          showGotoButton: true,
          onPressed: () => context.go(RouteNames.routinePath(elder.id)),
        ),
    ];

    if (cards.isEmpty) {
      return const _PendingTasksMessage(
        message: 'Nenhuma tarefa requer atenção neste momento.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          cards[index],
          if (index < cards.length - 1) SizedBox(height: sizes.sm),
        ],
      ],
    );
  }
}

class _PendingTasksMessage extends StatelessWidget {
  const _PendingTasksMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.appSizes.md),
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
}
