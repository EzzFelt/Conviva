import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class ContentPanelWidget extends StatelessWidget {
  const ContentPanelWidget({
    super.key,
    required this.child,
    this.topPanel,
    this.padding,
    this.topPanelPadding,
    this.margin,
    this.borderRadius,
  });

  final Widget child;
  final Widget? topPanel;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? topPanelPadding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.appSizes;
    final radius = Radius.circular(sizes.radiusLg + sizes.sm);
    final resolvedBorderRadius = borderRadius ?? BorderRadius.all(radius);

    Widget surfacePanel() {
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: resolvedBorderRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }

    if (topPanel == null) {
      return Container(
        width: double.infinity,
        margin: margin,
        child: surfacePanel(),
      );
    }

    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: resolvedBorderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: topPanelPadding ?? EdgeInsets.zero,
            child: topPanel,
          ),
          surfacePanel(),
        ],
      ),
    );
  }
}
