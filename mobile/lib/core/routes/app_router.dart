import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/models/auth_arguments.dart';
import '../../features/auth/pages/elder_login_page.dart';
import '../../features/auth/pages/family_link_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/chat/pages/chat_page.dart';
import '../../features/chat/pages/conversation_page.dart';
import '../../features/home/caregiver/caregiver_home_page.dart';
import '../../features/home/elder/elder_home_page.dart';
import '../../features/home/family/family_home_page.dart';
import '../../features/menu/pages/menu_page.dart';
import '../../features/onboarding/models/onboarding_arguments.dart';
import '../../features/onboarding/pages/onboarding_page.dart';
import '../../features/onboarding/pages/splash_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/routine/pages/routine_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/auri/pages/auri_page.dart';
import '../../shared/widgets/main_navigation_shell.dart';

import '../../features/reports/pages/report_start_page.dart';
import '../../features/reports/pages/report_form_page.dart';
import '../../features/reports/pages/report_offender_choice_page.dart';
import '../../features/reports/pages/report_select_person_page.dart';
import '../../features/reports/pages/report_success_page.dart';
import '../../features/reports/models/report_draft.dart';

import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        pageBuilder: (context, state) {
          final arguments =
              state.extra as OnboardingArguments? ??
              const OnboardingArguments();

          return CustomTransitionPage(
            key: state.pageKey,
            child: OnboardingPage(arguments: arguments),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          );
        },
      ),
      GoRoute(
        path: RouteNames.register,
        redirect: (context, state) {
          return state.extra is AuthArguments ? null : RouteNames.onboarding;
        },
        builder: (context, state) {
          return RegisterPage(arguments: state.extra as AuthArguments);
        },
      ),
      GoRoute(
        path: RouteNames.login,
        redirect: (context, state) {
          return state.extra is AuthArguments ? null : RouteNames.onboarding;
        },
        builder: (context, state) {
          return LoginPage(arguments: state.extra as AuthArguments);
        },
      ),
      GoRoute(
        path: RouteNames.elderLogin,
        redirect: (context, state) {
          return state.extra is AuthArguments ? null : RouteNames.onboarding;
        },
      ),
      
      GoRoute(
        path: RouteNames.familyLink,
              builder: (context, state) => const FamilyLinkPage(),
      ),

      GoRoute(
        path: RouteNames.reportStart,
        builder: (context, state) => const ReportStartPage(),
      ),

      GoRoute(
        path: RouteNames.reportForm,
        builder: (context, state) {
          final draft = state.extra is ReportDraft ? state.extra as ReportDraft : null;
          return ReportFormPage(initialDraft: draft);
        },
      ),

      GoRoute(
        path: RouteNames.reportOffenderChoice,
        builder: (context, state) {
          final draft = state.extra is ReportDraft ? state.extra as ReportDraft : const ReportDraft();
          return ReportOffenderChoicePage(draft: draft);
        },
      ),

      GoRoute(
        path: RouteNames.reportSelectPerson,
        builder: (context, state) {
          final draft = state.extra is ReportDraft ? state.extra as ReportDraft : const ReportDraft();
          return ReportSelectPersonPage(draft: draft);
        },
      ),

      GoRoute(
        path: RouteNames.reportSuccess,
        builder: (context, state) => const ReportSuccessPage(),
      ),

      GoRoute(
        path: RouteNames.elderHome,
        builder: (context, state) {
          return ElderLoginPage(arguments: state.extra as AuthArguments);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.familyLink,
            builder: (context, state) => const FamilyLinkPage(),
          ),
          GoRoute(
            path: RouteNames.elderHome,
            builder: (context, state) => const ElderHomePage(),
          ),
          GoRoute(
            path: RouteNames.caregiverHome,
            builder: (context, state) {
              final caregiverData = state.extra is Map<String, dynamic>
                  ? state.extra! as Map<String, dynamic>
                  : <String, dynamic>{};

              return CaregiverHomePage(caregiverData: caregiverData);
            },
          ),
          GoRoute(
            path: RouteNames.familyHome,
            builder: (context, state) {
              final elderName = state.extra is String
                  ? state.extra! as String
                  : 'Idoso';

              return FamilyHomePage(elderName: elderName);
            },
          ),
          GoRoute(
            path: RouteNames.menu,
            builder: (context, state) => const MenuPage(),
          ),
          GoRoute(
            path: RouteNames.chat,
            builder: (context, state) => const ChatPage(),
          ),
          GoRoute(
            path: RouteNames.chatConversation,
            builder: (context, state) {
              return ConversationPage(
                conversationId: state.pathParameters['conversationId']!,
              );
            },
          ),
          GoRoute(
            path: RouteNames.routine,
            builder: (context, state) => const RoutinePage(),
          ),
          GoRoute(
            path: RouteNames.routineDetail,
            builder: (context, state) {
              return RoutinePage(
                elderId: state.pathParameters['elderId']!,
              );
            },
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: RouteNames.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: RouteNames.auri,
            builder: (context, state) => const AuriPage(),
          ),
        ],
      ),
    ],
  );
}
