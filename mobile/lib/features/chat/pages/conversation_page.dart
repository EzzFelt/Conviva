import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
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
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _pendingMessages = <ChatMessage>[];
  bool _didScrollInitialMessages = false;
  bool _didMarkAsRead = false;
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  double _recordingAmplitude = -60;
  Timer? _recordingTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _sendMedia({
    required UserSession session,
    required ConversationPreview conversation,
    required String mediaUrl,
    required ChatMessageType type,
    required String text,
  }) async {
    if (mediaUrl.length > 680000) {
      _showUnavailable('O arquivo é muito grande para ser enviado.');
      return;
    }
    await sendMessage(
      currentUser: session,
      recipientId: conversation.participantId,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
    );
  }

  Future<void> _pickImage(
    UserSession session,
    ConversationPreview conversation,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 65,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _sendMedia(
      session: session,
      conversation: conversation,
      mediaUrl: base64Encode(bytes),
      type: ChatMessageType.image,
      text: '📷 Foto',
    );
  }

  Future<void> _toggleAudioRecording(
    UserSession session,
    ConversationPreview conversation,
  ) async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      await _amplitudeSubscription?.cancel();
      if (mounted) setState(() => _isRecording = false);
      if (path == null) return;
      final bytes = await File(path).readAsBytes();
      await _sendMedia(
        session: session,
        conversation: conversation,
        mediaUrl: base64Encode(bytes),
        type: ChatMessageType.audio,
        text: '🎵 Áudio',
      );
      return;
    }

    if (!await _audioRecorder.hasPermission()) {
      _showUnavailable('Permissão para usar o microfone não concedida.');
      return;
    }
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}${Platform.pathSeparator}chat_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: path,
    );
    _recordingPath = path;
    _recordingDuration = Duration.zero;
    _recordingAmplitude = -60;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
    });
    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amplitude) {
          if (mounted) setState(() => _recordingAmplitude = amplitude.current);
        });
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _cancelAudioRecording() async {
    if (!_isRecording) return;
    await _audioRecorder.stop();
    _recordingTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    final path = _recordingPath;
    _recordingPath = null;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
        _recordingAmplitude = -60;
      });
    }
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _sendMessage(
    UserSession session,
    ConversationPreview conversation,
  ) async {
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
    try {
      await sendMessage(
        currentUser: session,
        recipientId: conversation.participantId,
        text: text,
      );
      if (mounted) {
        setState(
          () => _pendingMessages.removeWhere(
            (message) =>
                message.text == text && message.senderId == session.uid,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _pendingMessages.removeWhere(
            (message) =>
                message.text == text && message.senderId == session.uid,
          ),
        );
        _showUnavailable('Não foi possível enviar a mensagem: $error');
      }
    }
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
          final messages = [...loadedMessages, ..._pendingMessages]
            ..sort((first, second) {
              return first.sentAt.compareTo(second.sentAt);
            });

          if (messages.isEmpty) {
            return const Center(child: Text('Envie a primeira mensagem.'));
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
                        sizes.sm,
                      ),
                      child: ChatMessageComposerWidget(
                        controller: _messageController,
                        onChanged: (_) => setState(() {}),
                        onSend: () => _sendMessage(session, conversation),
                        isRecording: _isRecording,
                        recordingDuration: _recordingDuration,
                        recordingAmplitude: _recordingAmplitude,
                        onCancelRecording: _cancelAudioRecording,
                        onMicrophonePressed: () =>
                            _toggleAudioRecording(session, conversation),
                        onEmojiPressed: () {
                          _showUnavailable(
                            'O seletor de emojis será disponibilizado em breve.',
                          );
                        },
                        onImagePressed: () => _pickImage(session, conversation),
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

              if (!_didMarkAsRead) {
                _didMarkAsRead = true;
                markAsRead(
                  chatId: widget.conversationId,
                  currentUserId: session.uid,
                );
              }
              return _content(context, session, conversation);
            },
          );
        },
      ),
    );
  }
}
