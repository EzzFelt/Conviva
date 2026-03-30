import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'features/onboarding/domain/repositories/onboarding_repository.dart';
import 'features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'features/onboarding/domain/usecases/complete_onboarding.dart';
import 'features/onboarding/presentation/bloc/onboarding_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientação (apenas portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ConvivaApp());
}

class ConvivaApp extends StatelessWidget {
  const ConvivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Repository Provider
        RepositoryProvider<OnboardingRepository>(
          create: (context) => OnboardingRepositoryImpl(
            localDataSource: OnboardingLocalDataSource(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Onboarding Bloc
          BlocProvider<OnboardingBloc>(
            create: (context) => OnboardingBloc(
              completeOnboardingUseCase: CompleteOnboarding(
                context.read<OnboardingRepository>(),
              ),
              checkOnboardingStatusUseCase: CheckOnboardingStatus(
                context.read<OnboardingRepository>(),
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Conviva',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
