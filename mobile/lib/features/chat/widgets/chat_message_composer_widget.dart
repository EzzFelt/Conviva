import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class ChatMessageComposerWidget extends StatelessWidget {
  const ChatMessageComposerWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSend,
    this.onMicrophonePressed,
    this.onEmojiPressed,
    this.onImagePressed,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback? onMicrophonePressed;
  final VoidCallback? onEmojiPressed;
  final VoidCallback? onImagePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final hasText = controller.text.trim().isNotEmpty;

    return Material(
      color: colorScheme.surface,
      shape: StadiumBorder(
        side: BorderSide(color: colorScheme.primary),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) {
                if (hasText) onSend();
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
            onPressed: hasText ? onSend : onMicrophonePressed,
            icon: Icon(
              hasText ? Icons.send_rounded : Icons.mic_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Emoji',
            onPressed: onEmojiPressed,
            icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
          ),
          IconButton(
            tooltip: 'Enviar imagem',
            onPressed: onImagePressed,
            icon: const Icon(Icons.image_rounded),
          ),
        ],
      ),
    );
  }
}
