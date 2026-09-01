import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class MainNavigationItem {
  const MainNavigationItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

const defaultMainNavigationItems = [
  MainNavigationItem(
    label: 'Início',
    icon: Icons.home_rounded,
  ),
  MainNavigationItem(
    label: 'Menu',
    icon: Icons.grid_view_rounded,
  ),
  MainNavigationItem(
    label: 'Perfil',
    icon: Icons.person_rounded,
  ),
  MainNavigationItem(
    label: 'Opções',
    icon: Icons.settings_rounded,
  ),
];

class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.items = defaultMainNavigationItems,
  }) : assert(
          items.length > 1 &&
              currentIndex >= 0 &&
              currentIndex < items.length,
        );

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<MainNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(sizes.radiusLg),
      topRight: Radius.circular(sizes.radiusLg),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: sizes.lg,
      ),
      child: Material(
        color: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.symmetric(horizontal: sizes.sm),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: sizes.xxl + sizes.xl + sizes.sm,
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;
                final color = isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: .60);

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: item.label,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => onDestinationSelected(index),
                      borderRadius: BorderRadius.circular(sizes.radiusMd),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.sm),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: sizes.icon(sizes.xl),
                              color: color,
                              fill: 1,
                            ),
                            SizedBox(height: sizes.xs),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
