import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/models/account_type.dart';
import '../../features/auth/models/auth_arguments.dart';
import '../../features/auth/pages/elder_login_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';

import '../../features/home/elder/elder_home_page.dart';
import '../../features/home/family/family_home_page.dart';
import '../../features/auth/pages/family_link_page.dart';

import '../../features/onboarding/models/onboarding_arguments.dart';
import '../../features/onboarding/pages/onboarding_page.dart';
import '../../features/onboarding/pages/splash_page.dart';

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
            child: OnboardingPage(
              arguments: arguments,
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),

      GoRoute(
        path: RouteNames.register,
        builder: (context, state) {
          final arguments = state.extra as AuthArguments;

          return RegisterPage(
            arguments: arguments,
          );
        },
      ),

      GoRoute(
        path: RouteNames.login,
        builder: (context, state) {
          final arguments = state.extra as AuthArguments;

          if (arguments.accountType == AccountType.elder) {
            return ElderLoginPage(
              arguments: arguments,
            );
          }

          return LoginPage(
            arguments: arguments,
          );
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
          final elderData = state.extra as Map<String, dynamic>? ?? const {};
          return ElderHomePage(
            elderData: elderData,
          );
        },
      ),

      GoRoute(
        path: RouteNames.familyHome,
        builder: (context, state) {
          final elderName = state.extra is String
              ? state.extra as String
              : 'Maria Antônia';
          return FamilyHomePage(elderName: elderName);
        },
      ),
    ],
  );
}
