import '../../domain/entities/user_type.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

/// Implementação do repositório de onboarding
/// 
/// Conecta a camada de domínio com a camada de dados.
/// Transforma dados do data source em entidades de domínio.
class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource localDataSource;

  OnboardingRepositoryImpl({required this.localDataSource});

  @override
  Future<bool> completeOnboarding() async {
    return await localDataSource.setOnboardingCompleted();
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    return await localDataSource.getOnboardingStatus();
  }

  @override
  Future<bool> saveUserType(UserType userType) async {
    return await localDataSource.saveUserType(userType.value);
  }

  @override
  Future<UserType?> getUserType() async {
    final userTypeString = await localDataSource.getUserType();
    if (userTypeString == null) return null;
    return UserType.fromString(userTypeString);
  }
}
