import 'package:flutter/material.dart';

class AuthFooterWidget extends StatelessWidget {
  const AuthFooterWidget({
    super.key,
    required this.text,
    required this.actionText,
    required this.onTap,
  });

  final String text;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyLarge,
            children: [
              TextSpan(text: text),
              TextSpan(
                text: ' $actionText',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
