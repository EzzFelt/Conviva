import 'package:flutter/widgets.dart';

import '../models/tutorial_step.dart';
import '../services/tutorial_target_registry.dart';

/// Marca usada na cópia do widget que o tutorial desenha acima da camada
/// escura. Os [TutorialTarget] dentro dela não se registram de novo.
class TutorialCloneScope extends InheritedWidget {
  const TutorialCloneScope({super.key, required super.child});

  @override
  bool updateShouldNotify(TutorialCloneScope oldWidget) => false;
}

/// Marca um widget como destacável pelo tutorial.
///
/// Não altera o visual nem o layout: apenas informa ao tutorial onde o
/// [child] está na tela e qual é o seu conteúdo, para que ele possa ser
/// desenhado em destaque, na frente da camada escura.
class TutorialTarget extends StatefulWidget {
  const TutorialTarget({super.key, required this.id, required this.child});

  final TutorialTargetId id;
  final Widget child;

  @override
  State<TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends State<TutorialTarget> {
  final LayerLink _link = LayerLink();
  TutorialTargetHandle? _handle;
  TutorialTargetId? _registeredId;

  @override
  void initState() {
    super.initState();

    final isClone =
        context.getInheritedWidgetOfExactType<TutorialCloneScope>() != null;

    if (!isClone) {
      _handle = TutorialTargetHandle(
        context: context,
        link: _link,
        child: widget.child,
      );
      _register();
    }
  }

  void _register() {
    final handle = _handle;
    if (handle == null) return;

    _registeredId = widget.id;
    TutorialTargetRegistry.instance.register(widget.id, handle);
  }

  void _unregister() {
    final handle = _handle;
    final id = _registeredId;
    if (handle == null || id == null) return;

    TutorialTargetRegistry.instance.unregister(id, handle);
    _registeredId = null;
  }

  @override
  void didUpdateWidget(covariant TutorialTarget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.id != widget.id) {
      _unregister();
      _register();
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handle = _handle;

    if (handle == null) return widget.child;

    handle.child = widget.child;

    return CompositedTransformTarget(link: _link, child: widget.child);
  }
}
