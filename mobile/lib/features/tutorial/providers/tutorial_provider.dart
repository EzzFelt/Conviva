import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/elder_tutorial_steps.dart';
import '../services/tutorial_target_registry.dart';

class TutorialState {
  const TutorialState({this.active = false, this.index = 0});

  final bool active;
  final int index;
}

final tutorialProvider = NotifierProvider<TutorialController, TutorialState>(
  TutorialController.new,
);

class TutorialController extends Notifier<TutorialState> {
  @override
  TutorialState build() => const TutorialState();

  void start() {
    state = const TutorialState(active: true, index: 0);
  }

  void next() {
    final current = elderTutorialSteps[state.index];
    var nextIndex = state.index + 1;

    // Pula na hora os passos opcionais da mesma tela cujo elemento não existe
    // (por exemplo, "editar tarefa" quando ainda não há tarefas). Assim a
    // tela não fica escura e sem balão esperando um elemento que não vem.
    while (nextIndex < elderTutorialSteps.length) {
      final candidate = elderTutorialSteps[nextIndex];
      final target = candidate.target;

      final canSkip =
          candidate.optional &&
          target != null &&
          candidate.route == current.route &&
          TutorialTargetRegistry.instance.handleOf(target) == null;

      if (!canSkip) break;
      nextIndex++;
    }

    if (nextIndex >= elderTutorialSteps.length) {
      finish();
      return;
    }

    state = TutorialState(active: true, index: nextIndex);
  }

  void finish() {
    state = const TutorialState();
  }
}
