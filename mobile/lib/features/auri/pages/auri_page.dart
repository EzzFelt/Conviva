import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/auri_avatar_widget.dart';
import '../../auth/providers/current_user_provider.dart';
import '../providers/auri_provider.dart';

class AuriPage extends ConsumerStatefulWidget {
  const AuriPage({super.key});

  @override
  ConsumerState<AuriPage> createState() => _AuriPageState();
}

class _AuriPageState extends ConsumerState<AuriPage> {
  final _controller = TextEditingController();
  final _messagesScrollController = ScrollController();
  final _tts = FlutterTts();
  final _speech = stt.SpeechToText();
  late final Future<dynamic> _ttsReady;
  bool _speechReady = false;
  bool _listening = false;
  bool _sending = false;
  bool _didScrollInitialMessages = false;
  String? _latestMessageId;

  static const _suggestions = [
    'Como mudo o papel de parede?',
    'Como envio foto no WhatsApp?',
    'Como assisto vídeos no YouTube?',
  ];

  @override
  void initState() {
    super.initState();
    _ttsReady = _tts.setLanguage('pt-BR');
  }

  @override
  void dispose() {
    _controller.dispose();
    _messagesScrollController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' && mounted) setState(() => _listening = false);
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    }
    if (!_speechReady) return;
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: 'pt_BR'),
      onResult: (result) {
        _controller.value = _controller.value.copyWith(
          text: result.recognizedWords,
          selection: TextSelection.collapsed(
            offset: result.recognizedWords.length,
          ),
        );
      },
    );
  }

  Future<void> _send([String? value]) async {
    final text = (value ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final session = await ref.read(currentUserProvider.future);
      if (session == null) {
        throw StateError('Usuário não autenticado.');
      }
      _controller.clear();
      await ref
          .read(auriServiceProvider)
          .ask(userId: session.uid, question: text);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível falar com o Auri: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToLatest();
      }
    }
  }

  Future<void> _speak(String text) async {
    await _ttsReady;
    await _tts.speak(text);
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messagesScrollController.hasClients) return;
      _messagesScrollController.animateTo(
        _messagesScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    final messages = ref.watch(auriMessagesProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, sizes),
            Expanded(
              child: messages.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Erro ao carregar o Auri: $error')),
                data: (snapshot) {
                  final docs = snapshot?.docs ?? const [];
                  if (docs.isEmpty) return _emptyState(sizes);
                  final latestId = docs.last.id;
                  if (latestId != _latestMessageId) {
                    _latestMessageId = latestId;
                    if (!_didScrollInitialMessages || _sending) {
                      _didScrollInitialMessages = true;
                      _scrollToLatest();
                    }
                  }
                  return ListView.builder(
                    controller: _messagesScrollController,
                    padding: EdgeInsets.all(sizes.lg),
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final data = docs[index].data();
                      final text = data['text']?.toString() ?? '';
                      final isAuri = data['sender'] == 'auri';
                      return Align(
                        alignment: isAuri
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: _bubble(text, isAuri, sizes),
                      );
                    },
                  );
                },
              ),
            ),
            if (_sending) const LinearProgressIndicator(minHeight: 2),
            _input(sizes),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppSizesTheme sizes) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.primary,
      padding: EdgeInsets.symmetric(horizontal: sizes.md, vertical: sizes.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.elderHome);
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: sizes.icon(sizes.lg),
              color: colorScheme.onPrimary,
            ),
          ),
          const Spacer(),
          Container(
            width: sizes.xxl + sizes.sm,
            height: sizes.xxl + sizes.sm,
            padding: EdgeInsets.all(sizes.sm),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appGradientColors.bottom,
            ),
            child: const AuriAvatarWidget(),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppSizesTheme sizes) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(sizes.lg),
      children: [
        SizedBox(height: sizes.xxl * 3),
        Text(
          'Como eu posso te ajudar?',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: sizes.lg),
        ..._suggestions.map(
          (suggestion) => Padding(
            padding: EdgeInsets.only(bottom: sizes.sm),
            child: ActionChip(
              label: Text(suggestion),
              onPressed: () => _send(suggestion),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(String text, bool isAuri, AppSizesTheme sizes) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width * .78;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: EdgeInsets.only(bottom: sizes.sm),
      padding: EdgeInsets.all(sizes.md),
      decoration: BoxDecoration(
        color: isAuri ? colorScheme.surfaceContainerLow : colorScheme.primary,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isAuri ? colorScheme.onSurface : colorScheme.onPrimary,
              ),
            ),
          ),
          if (isAuri)
            IconButton(
              tooltip: 'Ouvir resposta',
              visualDensity: VisualDensity.compact,
              onPressed: () => _speak(text),
              icon: Icon(
                Icons.volume_up_rounded,
                size: sizes.icon(sizes.lg),
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _input(AppSizesTheme sizes) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(sizes.radiusLg),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(sizes.lg, sizes.sm, sizes.lg, sizes.md),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _send(),
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Mensagem...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textHint,
          ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: sizes.md,
            vertical: sizes.sm,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: _listening ? 'Parar gravação' : 'Falar',
                onPressed: _toggleListening,
                icon: Icon(
                  _listening ? Icons.stop_circle_outlined : Icons.mic_none,
                  size: sizes.icon(sizes.lg),
                  color: _listening
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: 'Enviar',
                onPressed: _sending ? null : _send,
                icon: Icon(
                  Icons.send_rounded,
                  size: sizes.icon(sizes.lg),
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: inputBorder,
        ),
      ),
    );
  }
}
