import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/utils/profile_image.dart';
import '../../auth/models/account_type.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../chat/models/conversation_preview.dart';
import '../../chat/providers/conversation_previews_provider.dart';
import '../../chat/utils/chat_timestamp_formatter.dart';
import '../../routine/models/routine_elder_summary.dart';
import '../../routine/models/routine_task.dart';
import '../../routine/providers/routine_provider.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/routine_task_icon.dart';

class FamilyHomePage extends ConsumerStatefulWidget {
  const FamilyHomePage({super.key, this.elderId, this.elderName = 'Idoso'});

  final String? elderId;
  final String elderName;

  @override
  ConsumerState<FamilyHomePage> createState() => _FamilyHomePageState();
}

class _FamilyHomePageState extends ConsumerState<FamilyHomePage> {
  static const _selectedElderPreferencePrefix =
      'conviva_family_selected_elder_';

  final SharedPreferencesAsync _localStore = SharedPreferencesAsync();
  Future<void> _selectionSaveQueue = Future<void>.value();
  String? _selectedElderId;
  String? _selectionUserId;
  int _selectionVersion = 0;

  String _selectedElderPreferenceKey(String userId) {
    return '$_selectedElderPreferencePrefix$userId';
  }

  void _restoreSelectionFor(String userId) {
    _selectionUserId = userId;
    final version = ++_selectionVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectionUserId != userId) return;
      setState(() => _selectedElderId = null);
      unawaited(_loadSelectedElder(userId, version));
    });
  }

  Future<void> _loadSelectedElder(String userId, int version) async {
    try {
      final savedElderId = await _localStore.getString(
        _selectedElderPreferenceKey(userId),
      );
      if (!mounted ||
          _selectionUserId != userId ||
          _selectionVersion != version ||
          savedElderId == null) {
        return;
      }

      setState(() => _selectedElderId = savedElderId);
    } catch (error, stackTrace) {
      debugPrint('Erro ao carregar o idoso selecionado: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _selectElder(String elderId, String userId) {
    _selectionVersion++;
    setState(() => _selectedElderId = elderId);
    _selectionSaveQueue = _selectionSaveQueue.then((_) async {
      try {
        await _localStore.setString(
          _selectedElderPreferenceKey(userId),
          elderId,
        );
      } catch (error, stackTrace) {
        debugPrint('Erro ao salvar o idoso selecionado: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível salvar o idoso selecionado neste dispositivo.',
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradientColors = context.appGradientColors;
    final sizes = context.appSizes;
    final sessionState = ref.watch(currentUserProvider);
    final session = sessionState.hasValue ? sessionState.requireValue : null;
    if (session != null &&
        session.accountType == AccountType.family &&
        session.uid != _selectionUserId) {
      _restoreSelectionFor(session.uid);
    }
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
        elders.where((item) => item.id == _selectedElderId).firstOrNull ??
        elders.where((item) => item.id == widget.elderId).firstOrNull ??
        elders.firstOrNull;
    final resolvedElderId =
        elder?.id ??
        (eldersState.hasValue ? null : _selectedElderId ?? widget.elderId);
    final routineState = resolvedElderId == null
        ? null
        : ref.watch(routineTasksProvider(resolvedElderId));
    final linkedElderIds = linkedElderIdsState.hasValue
        ? linkedElderIdsState.requireValue
        : widget.elderId != null
        ? {widget.elderId!}
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
    final selectedElderConversations = familyConversations
        .where((conversation) => conversation.participantId == resolvedElderId)
        .toList();
    final isConversationLoading =
        !conversationsState.hasValue ||
        (!linkedElderIdsState.hasValue && widget.elderId == null);
    final conversationError =
        (conversationsState.hasError && !conversationsState.hasValue) ||
        (linkedElderIdsState.hasError && !linkedElderIdsState.hasValue);
    final latestConversation = selectedElderConversations.isEmpty
        ? null
        : selectedElderConversations.first;

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
                          if (elders.length > 1) ...[
                            Padding(
                              padding: EdgeInsets.only(
                                top: sizes.md,
                                bottom: sizes.md,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trocar o idoso visualizado',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        key: const ValueKey(
                                          'family-elder-selector',
                                        ),
                                        value: elder?.id ?? elders.first.id,
                                        isExpanded: true,
                                        items: [
                                          for (final linkedElder in elders)
                                            DropdownMenuItem(
                                              value: linkedElder.id,
                                              child: Text(
                                                linkedElder.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                        onChanged: (id) {
                                          if (id != null && session != null) {
                                            _selectElder(id, session.uid);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          _routineSummary(
                            context,
                            elder: elder,
                            elderId: resolvedElderId,
                            elderNameFallback: widget.elderName,
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
                          SizedBox(height: sizes.md),
                          Center(
                            child: SizedBox(
                              width: 280,
                              child: OutlinedButton(
                                key: const ValueKey('family-add-elder-button'),
                                onPressed: () =>
                                    context.push(RouteNames.familyLink),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.fromHeight(
                                    sizes.buttonMedium,
                                  ),
                                  backgroundColor:
                                      colorScheme.surfaceContainerLow,
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      sizes.radiusFull,
                                    ),
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
                          size: sizes.icon(sizes.lg),
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
    final timeLabel = familyHomeMessageTimestampLabel(
      conversation?.lastMessageAt,
    );

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
                      size: sizes.icon(sizes.lg),
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
