import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

enum AppModalSize {
  small,
  medium,
  large,
}

Future<T?> showAppModal<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  AppModalSize size = AppModalSize.medium,
  bool showCloseButton = true,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return AppModalWidget(
        title: title,
        size: size,
        showCloseButton: showCloseButton,
        onClose: () => Navigator.of(dialogContext).pop(),
        child: child,
      );
    },
  );
}

class AppModalWidget extends StatelessWidget {
  const AppModalWidget({
    super.key,
    required this.child,
    this.title,
    this.size = AppModalSize.medium,
    this.showCloseButton = true,
    this.onClose,
    this.padding,
  });

  final Widget child;
  final String? title;
  final AppModalSize size;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry? padding;

  double _maxWidth(AppSizesTheme sizes) {
    return switch (size) {
      AppModalSize.small => sizes.xxl * 5.5,
      AppModalSize.medium => sizes.xxl * 7,
      AppModalSize.large => sizes.xxl * 8,
    };
  }

  double _heightFactor() {
    return switch (size) {
      AppModalSize.small => .55,
      AppModalSize.medium => .72,
      AppModalSize.large => .88,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(sizes.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _maxWidth(sizes),
          maxHeight: screenSize.height * _heightFactor(),
        ),
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(sizes.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: padding ?? EdgeInsets.all(sizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null || showCloseButton)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (title != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: sizes.xl,
                          ),
                          child: Text(
                            title!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      if (showCloseButton)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Fechar',
                            onPressed: onClose ??
                                () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              size: sizes.icon(sizes.lg),
                            ),
                          ),
                        ),
                    ],
                  ),
                if (title != null || showCloseButton)
                  SizedBox(height: sizes.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
