import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../data/elder_tutorial_steps.dart';
import '../models/tutorial_step.dart';
import '../providers/tutorial_provider.dart';
import '../services/tutorial_target_registry.dart';
import 'tutorial_target.dart';

/// Camada do tutorial: escurece a tela, destaca o elemento do passo atual e
/// mostra o balão com a explicação.
///
/// Fica dentro do [MainNavigationShell], por cima da tela e da barra de
/// navegação. Quando o tutorial não está ativo, não ocupa nem bloqueia nada.
class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key, required this.location});

  /// Rota exibida no momento (usada para saber se é preciso navegar).
  final String location;

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  static const _settleTime = Duration(milliseconds: 500);
  static const _missingTimeout = Duration(seconds: 4);
  static const _optionalMissingTimeout = Duration(milliseconds: 1200);
  static const _bubbleMargin = 16.0;

  /// Espaço reservado embaixo para a barra de navegação ao rolar a tela.
  static const _bottomAllowance = 150.0;

  late final Ticker _ticker;

  int? _preparedIndex;
  Rect? _targetRect;
  bool _targetMissing = false;
  bool _scrolledIntoView = false;
  DateTime _stepStartedAt = DateTime.now();
  DateTime _settledAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _syncWithState(ref.read(tutorialProvider));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Prepara o passo atual: navega até a tela dele, se for outra, e começa a
  /// acompanhar a posição do elemento destacado.
  void _syncWithState(TutorialState tutorial) {
    if (!tutorial.active || tutorial.index >= elderTutorialSteps.length) {
      if (_ticker.isActive) _ticker.stop();
      _preparedIndex = null;
      _targetRect = null;
      _targetMissing = false;
      return;
    }

    if (_preparedIndex != tutorial.index) {
      _preparedIndex = tutorial.index;
      _targetRect = null;
      _targetMissing = false;
      _scrolledIntoView = false;
      _stepStartedAt = DateTime.now();
      _settledAt = _stepStartedAt;

      final step = elderTutorialSteps[tutorial.index];

      if (step.route != widget.location) {
        // Dá tempo para a transição de tela terminar antes de medir.
        _settledAt = _stepStartedAt.add(_settleTime);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          final current = ref.read(tutorialProvider);
          if (current.active && current.index == tutorial.index) {
            context.go(step.route);
          }
        });
      }
    }

    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    final tutorial = ref.read(tutorialProvider);
    if (!tutorial.active || _preparedIndex != tutorial.index) return;

    final step = elderTutorialSteps[tutorial.index];
    final targetId = step.target;

    if (targetId == null || step.route != widget.location) return;

    final now = DateTime.now();
    if (now.isBefore(_settledAt)) return;

    final overlayBox = context.findRenderObject();
    final targetContext = TutorialTargetRegistry.instance
        .handleOf(targetId)
        ?.context;
    final targetBox = _usableBox(targetContext);

    if (overlayBox is! RenderBox ||
        !overlayBox.hasSize ||
        targetContext == null ||
        targetBox == null) {
      final timeout = step.optional ? _optionalMissingTimeout : _missingTimeout;

      if (now.difference(_stepStartedAt) > timeout) {
        _handleMissingTarget(step);
      }
      return;
    }

    final rect =
        targetBox.localToGlobal(Offset.zero, ancestor: overlayBox) &
        targetBox.size;

    _scrollIntoViewIfNeeded(targetContext, rect, overlayBox.size);

    if (_targetRect != rect || _targetMissing) {
      setState(() {
        _targetRect = rect;
        _targetMissing = false;
      });
    }
  }

  RenderBox? _usableBox(BuildContext? targetContext) {
    if (targetContext == null || !targetContext.mounted) return null;

    final renderObject = targetContext.findRenderObject();

    if (renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize) {
      return renderObject;
    }

    return null;
  }

  void _scrollIntoViewIfNeeded(
    BuildContext targetContext,
    Rect rect,
    Size overlaySize,
  ) {
    if (_scrolledIntoView) return;
    _scrolledIntoView = true;

    if (Scrollable.maybeOf(targetContext) == null) return;

    final visibleTop = MediaQuery.paddingOf(context).top + 8;
    final visibleBottom = overlaySize.height - _bottomAllowance;

    if (rect.top >= visibleTop && rect.bottom <= visibleBottom) return;

    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.3,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _handleMissingTarget(TutorialStep step) {
    if (step.optional) {
      ref.read(tutorialProvider.notifier).next();
      return;
    }

    if (!_targetMissing) {
      setState(() => _targetMissing = true);
    }
  }

  void _next() {
    final tutorial = ref.read(tutorialProvider);
    final controller = ref.read(tutorialProvider.notifier);

    if (tutorial.index >= elderTutorialSteps.length - 1) {
      // Fim do tutorial: tela de parabéns.
      controller.finish();
      context.go(RouteNames.tutorialDone);
      return;
    }

    controller.next();
  }

  ({int current, int total}) _dotsFor(int index) {
    final title = elderTutorialSteps[index].title;
    final group = <int>[
      for (var i = 0; i < elderTutorialSteps.length; i++)
        if (elderTutorialSteps[i].title == title) i,
    ];

    return (current: group.indexOf(index), total: group.length);
  }

  @override
  Widget build(BuildContext context) {
    final tutorial = ref.watch(tutorialProvider);

    ref.listen<TutorialState>(tutorialProvider, (previous, next) {
      _syncWithState(next);
    });

    if (!tutorial.active || tutorial.index >= elderTutorialSteps.length) {
      return const SizedBox.shrink();
    }

    final step = elderTutorialSteps[tutorial.index];
    final hasTarget = step.target != null;
    final isReady = !hasTarget || _targetRect != null || _targetMissing;
    final dots = _dotsFor(tutorial.index);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Voltar durante o tutorial encerra o tutorial, sem sair da tela.
        if (!didPop) ref.read(tutorialProvider.notifier).finish();
      },
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final safePadding = MediaQuery.paddingOf(context);

            final targetRect = _targetRect;
            final spotlight = hasTarget && targetRect != null
                ? targetRect.inflate(step.spotlightPadding)
                : null;
            final handle = hasTarget
                ? TutorialTargetRegistry.instance.handleOf(step.target!)
                : null;
            final focusColor = switch (step.focus) {
              TutorialFocus.primary => Theme.of(context).colorScheme.primary,
              TutorialFocus.surface =>
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHigh
                    : Colors.white,
            };

            var anchor = hasTarget
                ? _BubbleAnchor.center
                : _BubbleAnchor.top;
            double? tailCenterX;
            var tailPointsUp = false;

            if (spotlight != null) {
              final spaceBelow =
                  size.height - spotlight.bottom - safePadding.bottom;
              final spaceAbove = spotlight.top - safePadding.top;
              const neededSpace = 210.0;

              final placeBelow =
                  spaceBelow >= neededSpace ||
                  (spaceAbove < neededSpace && spaceBelow >= spaceAbove);

              anchor = placeBelow
                  ? _BubbleAnchor.belowSpotlight
                  : _BubbleAnchor.aboveSpotlight;
              tailPointsUp = placeBelow;

              final bubbleWidth = size.width - _bubbleMargin * 2;
              tailCenterX = (spotlight.center.dx - _bubbleMargin)
                  .clamp(32.0, math.max(32.0, bubbleWidth - 32.0))
                  .toDouble();
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    // Bloqueia toques na tela enquanto o tutorial está ativo.
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: CustomPaint(
                      painter: _ScrimPainter(
                        spotlight: spotlight == null
                            ? null
                            : RRect.fromRectAndRadius(
                                spotlight,
                                Radius.circular(step.spotlightRadius),
                              ),
                        color: Colors.black.withValues(alpha: .62),
                      ),
                    ),
                  ),
                ),
                // O "foco": um fundo claro atrás do elemento e uma cópia do
                // próprio elemento, ambos desenhados na frente da camada
                // escura. Assim o destaque nunca fica coberto, seja qual for
                // a ordem de pintura da tela.
                if (spotlight != null && targetRect != null && handle != null) ...[
                  Positioned.fromRect(
                    rect: spotlight,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: focusColor,
                          borderRadius: BorderRadius.circular(
                            step.spotlightRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: CompositedTransformFollower(
                      link: handle.link,
                      showWhenUnlinked: false,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: SizedBox(
                            width: targetRect.width,
                            height: targetRect.height,
                            child: TutorialCloneScope(child: handle.child),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (isReady)
                  CustomSingleChildLayout(
                    delegate: _BubbleLayoutDelegate(
                      anchor: anchor,
                      spotlight: spotlight,
                      safePadding: safePadding,
                      horizontalMargin: _bubbleMargin,
                    ),
                    child: _TutorialBubble(
                      step: step,
                      dotIndex: dots.current,
                      dotCount: dots.total,
                      tailCenterX: tailCenterX,
                      tailPointsUp: tailPointsUp,
                      onNext: _next,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _BubbleAnchor { top, center, belowSpotlight, aboveSpotlight }

class _BubbleLayoutDelegate extends SingleChildLayoutDelegate {
  const _BubbleLayoutDelegate({
    required this.anchor,
    required this.spotlight,
    required this.safePadding,
    required this.horizontalMargin,
  });

  /// Distância entre o destaque e o balão (altura da setinha + folga).
  static const _gap = 20.0;

  final _BubbleAnchor anchor;
  final Rect? spotlight;
  final EdgeInsets safePadding;
  final double horizontalMargin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.max(0.0, constraints.maxWidth - horizontalMargin * 2);

    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final spot = spotlight;

    var y = switch (anchor) {
      _BubbleAnchor.top => safePadding.top + 56,
      _BubbleAnchor.center => (size.height - childSize.height) / 2,
      _BubbleAnchor.belowSpotlight =>
        (spot?.bottom ?? safePadding.top) + _gap,
      _BubbleAnchor.aboveSpotlight =>
        (spot?.top ?? size.height) - _gap - childSize.height,
    };

    final minY = safePadding.top + 8;
    final maxY = math.max(
      minY,
      size.height - safePadding.bottom - childSize.height - 8,
    );

    y = y.clamp(minY, maxY).toDouble();

    return Offset(horizontalMargin, y);
  }

  @override
  bool shouldRelayout(covariant _BubbleLayoutDelegate oldDelegate) {
    return oldDelegate.anchor != anchor ||
        oldDelegate.spotlight != spotlight ||
        oldDelegate.safePadding != safePadding ||
        oldDelegate.horizontalMargin != horizontalMargin;
  }
}

class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({required this.spotlight, required this.color});

  final RRect? spotlight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);

    final path = spotlight == null
        ? screen
        : Path.combine(
            PathOperation.difference,
            screen,
            Path()..addRRect(spotlight!),
          );

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter oldDelegate) {
    return oldDelegate.spotlight != spotlight || oldDelegate.color != color;
  }
}

class _TutorialBubble extends StatelessWidget {
  const _TutorialBubble({
    required this.step,
    required this.dotIndex,
    required this.dotCount,
    required this.tailCenterX,
    required this.tailPointsUp,
    required this.onNext,
  });

  static const _tailWidth = 24.0;
  static const _tailHeight = 14.0;

  final TutorialStep step;
  final int dotIndex;
  final int dotCount;

  /// Posição horizontal da setinha dentro do balão. Nulo = sem setinha.
  final double? tailCenterX;
  final bool tailPointsUp;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final bubbleColor = context.appGradientColors.bottom;
    final tailX = tailCenterX;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            sizes.lg - sizes.xs,
            sizes.md,
            sizes.md,
            sizes.md,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(sizes.radiusLg + sizes.sm),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.black.withValues(alpha: .55),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: sizes.sm),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.only(right: sizes.sm),
                  child: Text(
                    step.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
              if (step.note != null) ...[
                SizedBox(height: sizes.sm),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.only(right: sizes.sm),
                    child: Text(
                      step.note!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.black.withValues(alpha: .75),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: sizes.md),
              Row(
                children: [
                  if (step.showDots && dotCount > 1)
                    _TutorialDots(count: dotCount, current: dotIndex),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Próximo',
                    excludeSemantics: true,
                    child: Material(
                      color: colorScheme.primary,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onNext,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.onPrimary,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (tailX != null)
          Positioned(
            left: tailX - _tailWidth / 2,
            top: tailPointsUp ? -(_tailHeight - 1) : null,
            bottom: tailPointsUp ? null : -(_tailHeight - 1),
            child: CustomPaint(
              size: const Size(_tailWidth, _tailHeight),
              painter: _TailPainter(color: bubbleColor, pointsUp: tailPointsUp),
            ),
          ),
      ],
    );
  }
}

class _TutorialDots extends StatelessWidget {
  const _TutorialDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: 'Passo ${current + 1} de $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == current ? primary : Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter({required this.color, required this.pointsUp});

  final Color color;
  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    if (pointsUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }

    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointsUp != pointsUp;
  }
}
