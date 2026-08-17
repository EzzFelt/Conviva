import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/info_card_widget.dart';
import '../../../shared/widgets/main_navigation_bar.dart';

class FamilyHomePage extends StatelessWidget {
  const FamilyHomePage({
    super.key,
    this.elderName = 'Maria Antônia',
  });

  final String elderName;

  @override
  Widget build(BuildContext context) {
    final gradientColors = context.appGradientColors;
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    Widget scheduleCard(String title, String time, IconData icon) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: sizes.md,
            horizontal: sizes.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(sizes.radiusLg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colorScheme.primary, size: sizes.xl),
              SizedBox(height: sizes.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: sizes.xs),
              Text(
                time,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors.bottom,
              gradientColors.top,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sizes.lg,
                  sizes.lg,
                  sizes.lg,
                  sizes.md,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.surface,
                      child: const Icon(Icons.person_rounded),
                    ),
                    SizedBox(width: sizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            elderName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Mais importantes hoje:',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.notifications_rounded,
                            color: colorScheme.onPrimary,
                            size: sizes.xl,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '1',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onError,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(sizes.radiusLg + sizes.sm),
                      topRight: Radius.circular(sizes.radiusLg + sizes.sm),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(sizes.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            scheduleCard('Pilates', '14:30', Icons.sports_tennis_rounded),
                            SizedBox(width: sizes.sm),
                            scheduleCard('Leitura', '15:30', Icons.menu_book_rounded),
                            SizedBox(width: sizes.sm),
                            scheduleCard('Jantar', '19:30', Icons.restaurant_rounded),
                          ],
                        ),
                        SizedBox(height: sizes.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: sizes.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              'Ver rotina completa',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: sizes.xl),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Converse com seu parente',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: sizes.md),
                        InfoCardWidget(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withValues(alpha: .12),
                            child: Icon(Icons.person_rounded, color: colorScheme.primary),
                          ),
                          title: 'Oi, meu querido, como você está? Tudo bem?',
                          subtitle: '19:20',
                          size: InfoCardSize.medium,
                          showGotoButton: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              MainNavigationBar(
                currentIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
