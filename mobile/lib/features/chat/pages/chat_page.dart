import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';
import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/conversation_preview.dart';
import '../providers/conversation_previews_provider.dart';
import '../widgets/conversation_list_item_widget.dart';

enum _ConversationFilter { elder, caregiver, family }

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _searchController = TextEditingController();
  _ConversationFilter _elderFilter = _ConversationFilter.caregiver;
  _ConversationFilter _caregiverFilter = _ConversationFilter.elder;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ConversationPreview> _visibleConversations(
    UserSession session,
    List<ConversationPreview> conversations,
    Set<String> linkedFamilyIds,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return conversations.where((conversation) {
      final matchesAccountFilter = switch (session.accountType) {
        AccountType.elder => switch (_elderFilter) {
          _ConversationFilter.caregiver =>
            conversation.participantType ==
                ConversationParticipantType.caregiver,
          _ConversationFilter.family =>
            conversation.participantType == ConversationParticipantType.family,
          _ => false,
        },
        AccountType.caregiver => switch (_caregiverFilter) {
          _ConversationFilter.elder =>
            conversation.participantType == ConversationParticipantType.elder,
          _ConversationFilter.caregiver =>
            conversation.participantType ==
                ConversationParticipantType.caregiver,
          _ => false,
        },
        AccountType.family =>
          conversation.participantType == ConversationParticipantType.elder,
      };
      final requiresFamilyLink =
          (session.accountType == AccountType.elder &&
              conversation.participantType ==
                  ConversationParticipantType.family) ||
          session.accountType == AccountType.family;
      final matchesFamilyLink =
          !requiresFamilyLink ||
          linkedFamilyIds.contains(conversation.participantId);
      final matchesSearch =
          query.isEmpty ||
          conversation.participantName.toLowerCase().contains(query) ||
          conversation.lastMessage.toLowerCase().contains(query);

      return matchesAccountFilter && matchesFamilyLink && matchesSearch;
    }).toList();
  }

  Widget _filterButton({
    required String label,
    required _ConversationFilter value,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ButtonWidget(
        label: label,
        size: ButtonSize.small,
        variant: selected ? ButtonVariant.primary : ButtonVariant.outlined,
        onPressed: onPressed,
      ),
    );
  }

  Widget _filters(BuildContext context, UserSession session) {
    final sizes = context.appSizes;
    final filters = switch (session.accountType) {
      AccountType.elder => [
        (
          label: 'Cuidador',
          value: _ConversationFilter.caregiver,
          selected: _elderFilter == _ConversationFilter.caregiver,
        ),
        (
          label: 'Familiar',
          value: _ConversationFilter.family,
          selected: _elderFilter == _ConversationFilter.family,
        ),
      ],
      AccountType.caregiver => [
        (
          label: 'Idosos',
          value: _ConversationFilter.elder,
          selected: _caregiverFilter == _ConversationFilter.elder,
        ),
        (
          label: 'Cuidadores',
          value: _ConversationFilter.caregiver,
          selected: _caregiverFilter == _ConversationFilter.caregiver,
        ),
      ],
      AccountType.family => const [],
    };

    if (filters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: sizes.md),
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            if (index > 0) SizedBox(width: sizes.md),
            _filterButton(
              label: filters[index].label,
              value: filters[index].value,
              selected: filters[index].selected,
              onPressed: () {
                setState(() {
                  if (session.accountType == AccountType.elder) {
                    _elderFilter = filters[index].value;
                  } else {
                    _caregiverFilter = filters[index].value;
                  }
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(
    BuildContext context,
    String message, {
    IconData icon = Icons.chat_bubble_outline_rounded,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colorScheme.onSurfaceVariant,
              size: sizes.icon(sizes.xl),
            ),
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
      ),
    );
  }

  Widget _conversationList(
    BuildContext context,
    UserSession session,
    AsyncValue<List<ConversationPreview>> conversationsState,
    AsyncValue<List<InstitutionContact>> contactsState,
    AsyncValue<Set<String>> linkedFamilyIdsState,
  ) {
    final sizes = context.appSizes;

    return conversationsState.when(
      loading: () => Padding(
        padding: EdgeInsets.all(sizes.xxl),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _emptyState(
        context,
        'Não foi possível carregar as conversas.',
        icon: Icons.error_outline_rounded,
      ),
      data: (conversations) {
        if (contactsState.isLoading && contactsState.asData == null) {
          return Padding(
            padding: EdgeInsets.all(sizes.xxl),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (contactsState.hasError) {
          return _emptyState(
            context,
            'Não foi possível carregar os contatos da instituição.',
            icon: Icons.error_outline_rounded,
          );
        }

        final contacts =
            contactsState.asData?.value ?? const <InstitutionContact>[];
        final contactsById = {
          for (final contact in contacts) contact.uid: contact,
        };
        final institutionConversations = [
          for (final conversation in conversations)
            if (contactsById[conversation.participantId] case final contact?)
              ConversationPreview(
                id: conversation.id,
                participantId: contact.uid,
                participantName: contact.name,
                lastMessage: conversation.lastMessage,
                participantType: contact.type,
                photoUrl: contact.photoUrl ?? conversation.photoUrl,
                lastMessageAt: conversation.lastMessageAt,
                unreadCount: conversation.unreadCount,
              ),
        ];
        final knownParticipants = institutionConversations
            .map((conversation) => conversation.participantId)
            .toSet();
        final allConversations = [
          ...institutionConversations,
          for (final contact in contacts)
            if (!knownParticipants.contains(contact.uid))
              ConversationPreview(
                id: _chatId(session.uid, contact.uid),
                participantId: contact.uid,
                participantName: contact.name,
                lastMessage: '',
                participantType: contact.type,
                photoUrl: contact.photoUrl,
              ),
        ];
        final visible = _visibleConversations(
          session,
          allConversations,
          linkedFamilyIdsState.asData?.value ?? const <String>{},
        );
        if (visible.isEmpty) {
          return _emptyState(
            context,
            _searchController.text.trim().isEmpty
                ? 'Nenhum contato disponível para conversar.'
                : 'Nenhum contato encontrado.',
          );
        }

        return Column(
          children: [
            for (var index = 0; index < visible.length; index++) ...[
              ConversationListItemWidget(
                conversation: visible[index],
                onPressed: () {
                  context.go(
                    RouteNames.chatConversationPath(visible[index].id),
                  );
                },
              ),
              if (index < visible.length - 1) SizedBox(height: sizes.md),
            ],
          ],
        );
      },
    );
  }

  String _chatId(String firstId, String secondId) {
    final ids = [firstId, secondId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Widget _content(BuildContext context, UserSession session) {
    final sizes = context.appSizes;
    final conversationsState = ref.watch(conversationPreviewsProvider);
    final contactsState = ref.watch(institutionContactsProvider);
    final linkedFamilyIdsState = ref.watch(linkedFamilyIdsProvider);
    final panelRadius = Radius.circular(sizes.radiusLg + sizes.sm);

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
                title: 'Chat',
                onBackPressed: () => context.go(RouteNames.menu),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: ContentPanelWidget(
                borderRadius: BorderRadius.only(
                  topLeft: panelRadius,
                  topRight: panelRadius,
                ),
                padding: EdgeInsets.fromLTRB(
                  sizes.lg,
                  sizes.xl,
                  sizes.lg,
                  sizes.xxl * 3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFieldWidget(
                      controller: _searchController,
                      hintText: 'Pesquisar contato',
                      textInputAction: TextInputAction.search,
                      suffixIcon: Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: sizes.md),
                    _filters(context, session),
                    _conversationList(
                      context,
                      session,
                      conversationsState,
                      contactsState,
                      linkedFamilyIdsState,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              error.toString().replaceFirst('Bad state: ', ''),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Usuário não autenticado.'));
          }

          return _content(context, session);
        },
      ),
    );
  }
}
