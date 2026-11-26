import '../../../core/routes/route_names.dart';
import '../models/tutorial_step.dart';

/// Passos do tutorial do idoso, na ordem em que são exibidos.
///
/// Para incluir uma nova tela, basta adicionar novos [TutorialStep] aqui e
/// envolver o widget a destacar com `TutorialTarget`.
const elderTutorialSteps = <TutorialStep>[
  // Início
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Início do tutorial',
    message:
        'Agora vamos te explicar como funciona cada parte que você irá usar '
        'do aplicativo.',
    showDots: false,
  ),
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Início - 1',
    message:
        'Aqui no sino você pode ver as notificações de mensagens ou '
        'lembretes.',
    target: TutorialTargetId.homeBell,
    focus: TutorialFocus.primary,
    spotlightPadding: 6,
    spotlightRadius: 32,
  ),
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Início - 1',
    message:
        'Aqui você pode ver a próxima tarefa que você irá fazer no seu dia.',
    target: TutorialTargetId.homeNextTask,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Início - 1',
    message: 'Aqui mostra suas conversas, mostrando a última mensagem enviada.',
    target: TutorialTargetId.homeChat,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Início - 2',
    message:
        'Indo no botão "Comece agora" você poderá falar com o Auri, o nosso '
        'assistente virtual.',
    target: TutorialTargetId.homeAuri,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Início - 2',
    message:
        'Clicando aqui você será levado para a central de denúncias, '
        'podendo reportar uma irregularidade.',
    target: TutorialTargetId.homeReport,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),

  // Barra de navegação
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Barra de navegação - 1',
    message:
        'Esta é a nossa barra de navegação, usando ela você pode navegar '
        'pelo nosso aplicativo.',
    target: TutorialTargetId.navBar,
    spotlightPadding: 0,
    spotlightRadius: 32,
  ),
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Barra de navegação - 1',
    message:
        'Esta é a página que você acabou de conhecer, o início. Ela te dá '
        'uma visualização rápida de todas as funções do aplicativo.',
    target: TutorialTargetId.navHome,
    spotlightPadding: 2,
    spotlightRadius: 44,
  ),
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Barra de navegação - 1',
    message:
        'Este é o menu, onde você vai poder acessar rapidamente as funções '
        'do aplicativo, como sua rotina e o chat.',
    target: TutorialTargetId.navMenu,
    spotlightPadding: 2,
    spotlightRadius: 44,
  ),
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Barra de navegação - 2',
    message:
        'Este é o seu perfil, onde você pode ver e editar suas informações.',
    target: TutorialTargetId.navProfile,
    spotlightPadding: 2,
    spotlightRadius: 44,
  ),
  TutorialStep(
    route: RouteNames.elderHome,
    title: 'Tutorial - Barra de navegação - 2',
    message:
        'Esta é a configuração, nela você pode modificar novamente a '
        'aparência do aplicativo, além de acessar outras funções.',
    target: TutorialTargetId.navSettings,
    spotlightPadding: 2,
    spotlightRadius: 44,
  ),

  // Menu
  TutorialStep(
    route: RouteNames.menu,
    title: 'Tutorial - Menu',
    message:
        'Dentro do menu você vai ter quatro opções, com a primeira sendo a '
        'de rotina, para você visualizá-la.',
    target: TutorialTargetId.menuRoutine,
    spotlightPadding: 4,
    spotlightRadius: 24,
  ),
  TutorialStep(
    route: RouteNames.menu,
    title: 'Tutorial - Menu',
    message: 'A segunda é a do chat, para você abrir suas conversas.',
    target: TutorialTargetId.menuChat,
    spotlightPadding: 4,
    spotlightRadius: 24,
  ),
  TutorialStep(
    route: RouteNames.menu,
    title: 'Tutorial - Menu',
    message:
        'A terceira é a do assistente virtual, onde você poderá fazer '
        'perguntas para o Auri responder.',
    target: TutorialTargetId.menuAuri,
    spotlightPadding: 4,
    spotlightRadius: 24,
  ),
  TutorialStep(
    route: RouteNames.menu,
    title: 'Tutorial - Menu',
    message:
        'E por fim a quarta é a central de denúncias, na qual você pode '
        'reportar um abuso que esteja sofrendo.',
    target: TutorialTargetId.menuReport,
    spotlightPadding: 4,
    spotlightRadius: 24,
  ),

  // Rotina
  TutorialStep(
    route: RouteNames.routine,
    title: 'Tutorial - Rotina - 1',
    message:
        'Nesta tela de rotina, serão mostradas as informações do dia de '
        'hoje.',
    target: TutorialTargetId.routineDate,
    spotlightPadding: 6,
    spotlightRadius: 24,
  ),
  TutorialStep(
    route: RouteNames.routine,
    title: 'Tutorial - Rotina - 1',
    message:
        'Descendo a tela você vai ver a sua próxima tarefa, com o nome e o '
        'horário de começo e término dela.',
    target: TutorialTargetId.routineNextTask,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.routine,
    title: 'Tutorial - Rotina - 1',
    message:
        'Descendo mais você pode ver as próximas tarefas do seu dia. Aqui '
        'você pode editar a tarefa.',
    target: TutorialTargetId.routineEditTask,
    optional: true,
    spotlightPadding: 8,
    spotlightRadius: 20,
  ),

  TutorialStep(
    route: RouteNames.routine,
    title: 'Tutorial - Rotina - 1',
    message:
        'Clicando neste botão, você será levado para uma tela na qual você '
        'pode criar uma tarefa para você.',
    note:
        '(Se você está em uma casa de repouso, o cuidador irá criar e '
        'editar suas tarefas.)',
    target: TutorialTargetId.routineAddTask,
    optional: true,
    spotlightPadding: 8,
    spotlightRadius: 24,
  ),
  TutorialStep(
    route: RouteNames.routine,
    title: 'Tutorial - Rotina - 2',
    message:
        'Ao clicar nesse botão você pode visualizar o mês todo para ver as '
        'tarefas completas.',
    target: TutorialTargetId.routineToggle,
    routineAllDays: true,
    spotlightPadding: 8,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.routine,
    title: 'Tutorial - Rotina - 2',
    message:
        'Aqui você pode entrar em outros dias do mês para ver sua rotina '
        'nos próximos dias.',
    target: TutorialTargetId.routineCalendar,
    routineAllDays: true,
    spotlightPadding: 8,
    spotlightRadius: 28,
  ),

  // Configurações
  TutorialStep(
    route: RouteNames.settings,
    title: 'Tutorial - Configurações',
    message:
        'Esta é a configuração, nela você pode mexer novamente na aparência '
        'do aplicativo.',
    showDots: false,
  ),

  // Perfil
  TutorialStep(
    route: RouteNames.profile,
    title: 'Tutorial - Perfil',
    message:
        'Agora, no perfil, nesta parte você pode ver em qual instituto você '
        'se encontra.',
    target: TutorialTargetId.profileInstitute,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.profile,
    title: 'Tutorial - Perfil',
    message:
        'Suas informações pessoais serão mostradas aqui, sendo seu nome e '
        'seu telefone.',
    target: TutorialTargetId.profileInfo,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.profile,
    title: 'Tutorial - Perfil',
    message:
        'Clicando neste botão você pode editar suas informações, como nome '
        'e telefone.',
    target: TutorialTargetId.profileEdit,
    spotlightPadding: 8,
    spotlightRadius: 32,
  ),
  TutorialStep(
    route: RouteNames.profile,
    title: 'Tutorial - Perfil',
    message:
        'Aqui ficam os familiares vinculados a você, que podem acompanhar '
        'sua rotina e conversar com você. Quando um familiar pedir o '
        'vínculo, o pedido aparece logo acima para você aceitar ou recusar.',
    target: TutorialTargetId.profileFamilyLinks,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.profile,
    title: 'Tutorial - Perfil',
    message:
        'Aqui você pode escolher um familiar vinculado, um cuidador ativo ou '
        'ambos como responsáveis pela recuperação. Se precisar recuperar sua '
        'senha, qualquer responsável selecionado poderá aprovar o pedido.',
    target: TutorialTargetId.profileRecovery,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.profile,
    title: 'Tutorial - Perfil',
    message:
        'Este é o seu código de acesso. É com ele que seus familiares se '
        'vinculam a você. Para ver o código, é preciso digitar a sua senha.',
    target: TutorialTargetId.profileAccessCode,
    spotlightPadding: 12,
    spotlightRadius: 28,
  ),

  // Assistente virtual
  TutorialStep(
    route: RouteNames.auri,
    title: 'Tutorial - Assistente virtual',
    message:
        'Agora, dentro do assistente virtual, você vai poder mandar suas '
        'perguntas para o Auri respondê-las.',
    showDots: false,
  ),

  // Chat
  TutorialStep(
    route: RouteNames.chat,
    title: 'Tutorial - Chat',
    message:
        'Entrando no chat, caso você não ache a pessoa com quem deseja '
        'falar, pode clicar aqui e buscar pelo nome dela.',
    target: TutorialTargetId.chatSearch,
    spotlightPadding: 8,
    spotlightRadius: 32,
  ),
  TutorialStep(
    route: RouteNames.chat,
    title: 'Tutorial - Chat',
    message:
        'Estes botões te ajudam a escolher com qual pessoa falar, podendo '
        'escolher entre falar com um cuidador ou com um familiar.',
    target: TutorialTargetId.chatFilters,
    spotlightPadding: 8,
    spotlightRadius: 28,
  ),
  TutorialStep(
    route: RouteNames.chat,
    title: 'Tutorial - Chat',
    message:
        'Você pode ver o nome, a última mensagem que a pessoa te mandou e a '
        'hora. O símbolo vermelho sinaliza uma nova mensagem.',
    target: TutorialTargetId.chatConversation,
    optional: true,
    spotlightPadding: 6,
    spotlightRadius: 28,
  ),

  // Central de denúncias
  TutorialStep(
    route: RouteNames.reportStart,
    title: 'Tutorial - Central de denúncias',
    message:
        'Por fim, nesta área você poderá realizar uma denúncia caso precise '
        'ou sinta necessidade.',
    showDots: false,
  ),
];
