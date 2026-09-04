class RouteNames {
  RouteNames._();

  static const splash = '/';
  static const onboarding = '/onboarding';

  static const register = '/register';
  static const login = '/login';
  static const elderLogin = '/login/elder';
  static const familyLink = '/family-link';

  static const elderHome = '/home/elder';
  static const caregiverHome = '/home/caregiver';
  static const familyHome = '/home/family';

  static const menu = '/menu';
  static const chat = '/chat';
  static const chatConversation = '/chat/:conversationId';
  static const routine = '/routine';
  static const routineDetail = '/routine/:elderId';
  static const profile = '/profile';
  static const settings = '/settings';
  static const auri = '/auri';
  static const reportStart = '/reports';
  static const reportType = '/reports/type';
  static const reportForm = '/reports/form';
  static const reportOffenderChoice = '/reports/offender';
  static const reportSelectPerson = '/reports/person';
  static const reportSuccess = '/reports/success';

  static String chatConversationPath(String conversationId) {
    return '/chat/${Uri.encodeComponent(conversationId)}';
  }

  static String routinePath(String elderId) {
    return '/routine/${Uri.encodeComponent(elderId)}';
  }
}
