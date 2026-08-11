import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/action_card_widget.dart';

class ElderSupportSection extends StatelessWidget {
  const ElderSupportSection({
    super.key,
    required this.onAssistantPressed,
    required this.onReportPressed,
  });

  final VoidCallback onAssistantPressed;
  final VoidCallback onReportPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    Widget illustration(IconData icon) {
      return Container(
        width: sizes.xxl * 1.5,
        height: sizes.xxl * 1.5,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: .82),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: sizes.xxl,
          color: colorScheme.onPrimary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assistente Virtual -\nTire Dúvidas',
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: sizes.md),
        ActionCardWidget(
          title: 'Tire dúvidas sobre tecnologia com o Auri',
          illustration: illustration(Icons.smart_toy_rounded),
          actionLabel: 'Comece agora!',
          onPressed: onAssistantPressed,
        ),
        SizedBox(height: sizes.xxl),
        Text(
          'Central de Denúncias -\nDenuncie',
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: sizes.md),
        ActionCardWidget(
          title: 'Denuncie abusos que estiver sofrendo de maneira anônima',
          illustration: illustration(Icons.report_rounded),
          actionLabel: 'Denuncie!',
          onPressed: onReportPressed,
        ),
      ],
    );
  }
}
