import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/chat_message.dart';
import '../models/conversation_preview.dart';
import '../providers/chat_messages_provider.dart';
import '../providers/conversation_previews_provider.dart';
import '../widgets/chat_avatar_widget.dart';
import '../widgets/chat_message_bubble_widget.dart';
import '../widgets/chat_message_composer_widget.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() =>
      _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _pendingMessages = <ChatMessage>[];
  bool _didScrollInitialMessages = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage(UserSession session) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _pendingMessages.add(
        ChatMessage(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          conversationId: widget.conversationId,
          senderId: session.uid,
          sentAt: DateTime.now(),
          text: text,
        ),
      );
      _messageController.clear();
    });
    _scrollToEnd();
  }

  String _dateLabel() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return 'Hoje, $day/$month/${now.year}, $hour:$minute';
  }

  Widget _messages(
    BuildContext context,
    UserSession session,
    ConversationPreview conversation,
  ) {
    final sizes = context.appSizes;
    final messagesState = ref.watch(
      chatMessagesProvider(widget.conversationId),
    );

    return Expanded(
      child: messagesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Não foi possível carregar as mensagens.'),
        ),
        data: (loadedMessages) {
          final messages = [
            ...loadedMessages,
            ..._pendingMessages,
          ]..sort((first, second) {
              return first.sentAt.compareTo(second.sentAt);
            });

          if (messages.isEmpty) {
            return const Center(
              child: Text('Envie a primeira mensagem.'),
            );
          }

          if (!_didScrollInitialMessages) {
            _didScrollInitialMessages = true;
            _scrollToEnd();
          }
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              sizes.md,
              sizes.lg,
              sizes.md,
              sizes.md,
            ),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ChatMessageBubbleWidget(
                message: message,
                isCurrentUser: message.isFrom(session.uid),
                participantType: conversation.participantType,
                participantPhotoUrl: conversation.photoUrl,
              );
            },
          );
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    UserSession session,
    ConversationPreview conversation,
  ) {
    final sizes = context.appSizes;
    final colorScheme = Theme.of(context).colorScheme;

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
              title: conversation.participantName,
              titleLeading: ChatAvatarWidget(
                participantType: conversation.participantType,
                photoUrl: conversation.photoUrl,
                size: sizes.buttonSmall,
              ),
              onBackPressed: () => context.go(RouteNames.chat),
              trailing: IconButton(
                tooltip: 'Ligar',
                onPressed: () {
                  _showUnavailable(
                    'As chamadas serão disponibilizadas em breve.',
                  );
                },
                icon: Icon(
                  Icons.call_rounded,
                  color: colorScheme.onPrimary,
                  size: sizes.icon(sizes.lg),
                ),
              ),
            ),
            Expanded(
              child: ContentPanelWidget(
                borderRadius: BorderRadius.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: sizes.sm),
                      child: Text(
                        _dateLabel(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    _messages(context, session, conversation),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        sizes.sm,
                        sizes.sm,
                        sizes.sm,
                        sizes.xxl * 2 + sizes.lg,
                      ),
                      child: ChatMessageComposerWidget(
                        controller: _messageController,
                        onChanged: (_) => setState(() {}),
                        onSend: () => _sendMessage(session),
                        onMicrophonePressed: () {
                          _showUnavailable(
                            'O envio de áudio será disponibilizado em breve.',
                          );
                        },
                        onEmojiPressed: () {
                          _showUnavailable(
                            'O seletor de emojis será disponibilizado em breve.',
                          );
                        },
                        onImagePressed: () {
                          _showUnavailable(
                            'O envio de imagens será disponibilizado em breve.',
                          );
                        },
                      ),
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
    final conversationState = ref.watch(
      conversationPreviewProvider(widget.conversationId),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: currentUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Usuário não autenticado.'));
          }

          return conversationState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (conversation) {
              if (conversation == null) {
                return const Center(child: Text('Conversa não encontrada.'));
              }

              return _content(context, session, conversation);
            },
          );
        },
      ),
    );
  }
}
