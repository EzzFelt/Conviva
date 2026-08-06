import 'account_type.dart';

extension AccountTypeExtensions on AccountType {
  bool get hasPassword {
    return this != AccountType.elder;
  }

  bool get hasInstitution {
    return this == AccountType.caregiver;
  }

  String get title {
    switch (this) {
      case AccountType.elder:
        return 'Idoso';

      case AccountType.caregiver:
        return 'Cuidador';

      case AccountType.family:
        return 'Familiar';
    }
  }
}