/// Elementos da interface que o tutorial pode destacar.
///
/// Cada valor é ligado a um widget real do app por meio do
/// `TutorialTarget(id: ...)`.
enum TutorialTargetId {
  // Início do idoso
  homeBell,
  homeNextTask,
  homeChat,
  homeAuri,
  homeReport,

  // Barra de navegação
  navBar,
  navHome,
  navMenu,
  navProfile,
  navSettings,

  // Menu
  menuRoutine,
  menuChat,
  menuAuri,
  menuReport,

  // Rotina
  routineDate,
  routineNextTask,
  routineEditTask,
  routineAddTask,
  routineToggle,
  routineCalendar,

  // Perfil
  profileInstitute,
  profileInfo,
  profileEdit,
  profileFamilyLinks,
  profileRecovery,
  profileAccessCode,

  // Chat
  chatSearch,
  chatFilters,
  chatConversation,
}

/// Cor do "foco" desenhado atrás do elemento destacado.
enum TutorialFocus {
  /// Fundo claro (branco), usado na maioria dos elementos.
  surface,

  /// Cor principal do app. Usada quando o elemento tem ícone branco, como o
  /// sino do cabeçalho.
  primary,
}

/// Um passo do tutorial: uma tela, um elemento destacado e o texto do balão.
class TutorialStep {
  const TutorialStep({
    required this.route,
    required this.title,
    required this.message,
    this.target,
    this.showDots = true,
    this.optional = false,
    this.note,
    this.routineAllDays,
    this.focus = TutorialFocus.surface,
    this.spotlightPadding = 10,
    this.spotlightRadius = 24,
  });

  /// Rota onde o passo acontece. O tutorial navega até ela se necessário.
  final String route;

  /// Texto pequeno acima da mensagem. Passos com o mesmo [title] formam um
  /// grupo e dividem a mesma sequência de bolinhas.
  final String title;

  final String message;

  /// Elemento destacado. Quando é nulo, o passo só mostra o balão.
  final TutorialTargetId? target;

  final bool showDots;

  /// Se o elemento não existir na tela (por exemplo, uma tarefa ainda não
  /// criada), o passo é pulado em vez de aparecer sem destaque.
  final bool optional;

  /// Texto menor mostrado abaixo da mensagem (por exemplo, um aviso entre
  /// parênteses).
  final String? note;

  /// Na tela de rotina: `true` mostra "Todos dias", `false` mostra "Hoje".
  /// Nulo não altera a visualização.
  final bool? routineAllDays;

  final TutorialFocus focus;

  final double spotlightPadding;
  final double spotlightRadius;
}

/// Alvos dos cards do menu do idoso, na ordem em que aparecem.
const elderMenuTutorialTargets = [
  TutorialTargetId.menuRoutine,
  TutorialTargetId.menuChat,
  TutorialTargetId.menuAuri,
  TutorialTargetId.menuReport,
];
