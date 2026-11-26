import 'package:flutter/widgets.dart';

import '../models/tutorial_step.dart';

/// Tudo o que o tutorial precisa saber sobre um widget destacável.
class TutorialTargetHandle {
  TutorialTargetHandle({
    required this.context,
    required this.link,
    required this.child,
  });

  /// Contexto do widget original (usado para medir posição e tamanho).
  final BuildContext context;

  /// Ligação com a posição do widget original na tela.
  final LayerLink link;

  /// Último conteúdo do widget, usado para desenhá-lo acima da camada escura.
  Widget child;
}

/// Lista dos widgets que estão na tela e podem ser destacados pelo tutorial.
class TutorialTargetRegistry {
  TutorialTargetRegistry._();

  static final instance = TutorialTargetRegistry._();

  final Map<TutorialTargetId, TutorialTargetHandle> _targets = {};

  void register(TutorialTargetId id, TutorialTargetHandle handle) {
    _targets[id] = handle;
  }

  void unregister(TutorialTargetId id, TutorialTargetHandle handle) {
    if (identical(_targets[id], handle)) {
      _targets.remove(id);
    }
  }

  TutorialTargetHandle? handleOf(TutorialTargetId id) => _targets[id];
}
