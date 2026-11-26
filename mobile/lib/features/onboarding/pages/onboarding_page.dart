import 'package:flutter/material.dart';

import '../../auth/models/auth_mode.dart';
import '../models/onboarding_arguments.dart';
import '../models/onboarding_items.dart';
import '../widgets/account_page.dart';
import '../widgets/onboarding_content.dart';

class OnboardingPage extends StatefulWidget {
  final OnboardingArguments arguments;

  const OnboardingPage({
    super.key,
    this.arguments = const OnboardingArguments(),
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _pageTransitionDuration = Duration(milliseconds: 400);

  late final PageController _pageController;
  late int _currentPage;
  late AuthMode _authMode;

  int _validPage(int page) {
    return page
        .clamp(OnboardingPages.intro, OnboardingPages.accountType)
        .toInt();
  }

  @override
  void initState() {
    super.initState();

    _currentPage = _validPage(widget.arguments.initialPage);
    _authMode = widget.arguments.authMode;

    _pageController = PageController(
      initialPage: _currentPage,
    );
  }

  @override
  void didUpdateWidget(covariant OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final pageChanged =
        oldWidget.arguments.initialPage != widget.arguments.initialPage;
    final modeChanged =
        oldWidget.arguments.authMode != widget.arguments.authMode;

    if (pageChanged || modeChanged) {
      _currentPage = _validPage(widget.arguments.initialPage);
      _authMode = widget.arguments.authMode;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < OnboardingPages.accountType) {
      _pageController.nextPage(
        duration: _pageTransitionDuration,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _openAccountType(AuthMode mode) {
    setState(() {
      _authMode = mode;
    });

    _pageController.animateToPage(
      OnboardingPages.accountType,
      duration: _pageTransitionDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: OnboardingPages.accountType + 1,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          if (index < OnboardingPages.accountType) {
            return OnboardingContent(
              pageIndex: index,
              indicatorCount: onboardingItems.length,
              item: onboardingItems[index],
              isLastOnboarding: index == onboardingItems.length - 1,
              onContinue: index == onboardingItems.length - 1
                  ? () => _openAccountType(AuthMode.register)
                  : _nextPage,
              onLogin: () => _openAccountType(AuthMode.login),
            );
          }

          return AccountTypePage(
            authMode: _authMode,
            onBack: () {
              _pageController.previousPage(
                duration: _pageTransitionDuration,
                curve: Curves.easeInOutCubic,
              );
            },
          );
        },
      ),
    );
  }
}
