import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';
import '../../auth/providers/current_user_provider.dart';
import '../providers/auri_provider.dart';

class AuriPage extends ConsumerStatefulWidget {
  const AuriPage({super.key});

  @override
  ConsumerState<AuriPage> createState() => _AuriPageState();
}

class _AuriPageState extends ConsumerState<AuriPage> {
  final _controller = TextEditingController();
  final _tts = FlutterTts();
  final _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  bool _sending = false;

  static const _suggestions = [
    'Como mudo o papel de parede?',
    'Como envio foto no WhatsApp?',
    'Como assisto vídeos no YouTube?',
  ];

  @override
  void dispose() {
    _controller.dispose();
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
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && mounted) setState(() => _listening = false);
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
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
    final session = await ref.read(currentUserProvider.future);
    if (session == null) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      await ref
          .read(auriServiceProvider)
          .ask(userId: session.uid, question: text);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível falar com o Auri: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage('pt-BR');
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    final messages = ref.watch(auriMessagesProvider);
    return Scaffold(
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
                  return ListView.builder(
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
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xs),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.elderHome);
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Spacer(),
          Image.asset(AssetPaths.auri, width: 42, height: 42),
        ],
      ),
    );
  }

  Widget _emptyState(AppSizesTheme sizes) {
    return ListView(
      padding: EdgeInsets.all(sizes.lg),
      children: [
        SizedBox(height: sizes.xxl * 2),
        Text(
          'Como eu posso te ajudar?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
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
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: EdgeInsets.only(bottom: sizes.sm),
      padding: EdgeInsets.all(sizes.md),
      decoration: BoxDecoration(
        color: isAuri ? Colors.grey.shade100 : AppColors.primary,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: isAuri ? AppColors.textPrimary : Colors.white,
              ),
            ),
          ),
          if (isAuri)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _speak(text),
              icon: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _input(AppSizesTheme sizes) {
    return Padding(
      padding: EdgeInsets.fromLTRB(sizes.md, sizes.sm, sizes.md, sizes.md),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _send(),
        decoration: InputDecoration(
          hintText: 'Mensagem...',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: _listening ? 'Parar gravação' : 'Falar',
                onPressed: _toggleListening,
                icon: Icon(
                  _listening ? Icons.stop_circle_outlined : Icons.mic_none,
                ),
              ),
              IconButton(
                tooltip: 'Enviar',
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sizes.radiusFull),
          ),
        ),
      ),
    );
  }
}
