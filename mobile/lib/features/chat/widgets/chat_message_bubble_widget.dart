import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../models/chat_message.dart';
import '../models/conversation_preview.dart';
import 'chat_avatar_widget.dart';

class ChatMessageBubbleWidget extends StatelessWidget {
  const ChatMessageBubbleWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.participantType,
    this.participantPhotoUrl,
  });

  final ChatMessage message;
  final bool isCurrentUser;
  final ConversationParticipantType participantType;
  final String? participantPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final bubbleColor = isCurrentUser
        ? colorScheme.primary
        : theme.scaffoldBackgroundColor;
    final textColor = isCurrentUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: sizes.sm),
        child: Row(
          mainAxisAlignment: isCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser) ...[
              ChatAvatarWidget(
                participantType: participantType,
                photoUrl: participantPhotoUrl,
                size: sizes.lg,
              ),
              SizedBox(width: sizes.sm),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * .7,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: sizes.md,
                  vertical: sizes.sm,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(sizes.radiusMd),
                ),
                child: _messageContent(context, textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageContent(BuildContext context, Color textColor) {
    if (message.type == ChatMessageType.image && message.mediaUrl != null) {
      try {
        return GestureDetector(
          onTap: () => _showImage(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(message.mediaUrl!),
              width: MediaQuery.sizeOf(context).width * .7,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Text(message.text),
            ),
          ),
        );
      } on FormatException {
        return Text(message.text);
      }
    }
    if (message.type == ChatMessageType.audio && message.mediaUrl != null) {
      return _AudioMessagePlayer(
        base64Data: message.mediaUrl!,
        color: textColor,
      );
    }
    return Text(
      message.text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor),
    );
  }

  void _showImage(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: InteractiveViewer(
          minScale: .5,
          maxScale: 4,
          child: Image.memory(base64Decode(message.mediaUrl!)),
        ),
      ),
    );
  }
}

class _AudioMessagePlayer extends StatefulWidget {
  const _AudioMessagePlayer({required this.base64Data, required this.color});
  final String base64Data;
  final Color color;

  @override
  State<_AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<_AudioMessagePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;
  String? _filePath;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final directory = await getTemporaryDirectory();
    _filePath ??=
        '${directory.path}${Platform.pathSeparator}chat_${widget.base64Data.hashCode}.m4a';
    final file = File(_filePath!);
    if (!await file.exists()) {
      await file.writeAsBytes(base64Decode(widget.base64Data), flush: true);
    }
    await _player.play(DeviceFileSource(_filePath!));
    if (mounted) setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds)
              .clamp(0, 1)
              .toDouble();
    return StreamBuilder<Duration>(
      stream: _player.onPositionChanged,
      builder: (context, positionSnapshot) {
        _position = positionSnapshot.data ?? _position;
        return StreamBuilder<Duration>(
          stream: _player.onDurationChanged,
          builder: (context, durationSnapshot) {
            _duration = durationSnapshot.data ?? _duration;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _playing ? 'Pausar áudio' : 'Reproduzir áudio',
                  onPressed: _toggle,
                  style: IconButton.styleFrom(
                    backgroundColor: widget.color.withValues(alpha: .16),
                  ),
                  icon: Icon(
                    _playing ? Icons.pause : Icons.play_arrow,
                    color: widget.color,
                  ),
                ),
                SizedBox(
                  width: 110,
                  height: 28,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      color: widget.color,
                      progress: progress,
                    ),
                  ),
                ),
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(color: widget.color, fontSize: 11),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 3;
    const heights = [8.0, 16, 11, 21, 13, 24, 10, 18, 8, 15, 22, 12];
    for (var index = 0; index < heights.length; index++) {
      final x = (index + .5) * size.width / heights.length;
      paint.color = index / heights.length <= progress
          ? color
          : color.withValues(alpha: .28);
      canvas.drawLine(
        Offset(x, (size.height - heights[index]) / 2),
        Offset(x, (size.height + heights[index]) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
