import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../../../core/constants/app_sizes.dart';

class ChatMessageComposerWidget extends StatefulWidget {
  const ChatMessageComposerWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSend,
    this.onMicrophonePressed,
    this.onEmojiPressed,
    this.onImagePressed,
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.recordingAmplitude = 0,
    this.onCancelRecording,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback? onMicrophonePressed;
  final VoidCallback? onEmojiPressed;
  final VoidCallback? onImagePressed;
  final bool isRecording;
  final Duration recordingDuration;
  final double recordingAmplitude;
  final VoidCallback? onCancelRecording;

  @override
  State<ChatMessageComposerWidget> createState() =>
      _ChatMessageComposerWidgetState();
}

class _ChatMessageComposerWidgetState extends State<ChatMessageComposerWidget> {
  bool _showEmojiPicker = false;
  final _inputFocusNode = FocusNode();

  @override
  void dispose() {
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: colorScheme.surface,
          shape: StadiumBorder(side: BorderSide(color: colorScheme.primary)),
          clipBehavior: Clip.antiAlias,
          child: widget.isRecording
              ? _RecordingBar(
                  duration: widget.recordingDuration,
                  amplitude: widget.recordingAmplitude,
                  onCancel: widget.onCancelRecording,
                  onStop: widget.onMicrophonePressed,
                )
              : Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _inputFocusNode,
                        onChanged: widget.onChanged,
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() => _showEmojiPicker = false);
                          }
                        },
                        onSubmitted: (_) {
                          if (hasText) widget.onSend();
                        },
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Escreva a mensagem',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: sizes.md,
                            vertical: sizes.sm,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: hasText ? 'Enviar' : 'Gravar áudio',
                      onPressed: hasText
                          ? widget.onSend
                          : widget.onMicrophonePressed,
                      icon: Icon(
                        hasText
                            ? Icons.send_rounded
                            : widget.isRecording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Emoji',
                      onPressed: () {
                        setState(() => _showEmojiPicker = !_showEmojiPicker);
                        if (!_showEmojiPicker) {
                          _inputFocusNode.requestFocus();
                        } else {
                          FocusScope.of(context).unfocus();
                        }
                      },
                      icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                    ),
                    IconButton(
                      tooltip: 'Enviar imagem',
                      onPressed: widget.onImagePressed,
                      icon: const Icon(Icons.image_rounded),
                    ),
                  ],
                ),
        ),
        if (_showEmojiPicker && !widget.isRecording)
          SizedBox(
            height: 256,
            child: EmojiPicker(
              textEditingController: widget.controller,
              config: const Config(
                height: 256,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(columns: 7, emojiSizeMax: 28),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    required this.duration,
    required this.amplitude,
    required this.onCancel,
    required this.onStop,
  });

  final Duration duration;
  final double amplitude;
  final VoidCallback? onCancel;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    final colorScheme = Theme.of(context).colorScheme;
    final seconds = duration.inSeconds;
    final time = '0:${(seconds % 60).toString().padLeft(2, '0')}';
    final normalizedAmplitude = ((amplitude + 60) / 60).clamp(.08, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sizes.sm, vertical: sizes.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancelar gravação',
            onPressed: onCancel,
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
          ),
          Text(time, style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(width: sizes.sm),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(18, (index) {
                final variation = 0.35 + ((index % 5) / 10);
                final height = 8 + 26 * normalizedAmplitude * variation;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: height,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
          IconButton(
            tooltip: 'Enviar áudio',
            onPressed: onStop,
            icon: Icon(Icons.send_rounded, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
