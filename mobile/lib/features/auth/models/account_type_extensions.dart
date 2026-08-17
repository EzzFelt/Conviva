import 'account_type.dart';

extension AccountTypeExtensions on AccountType {
  bool get hasPassword {
    return true;
  }

  bool get hasInstitution {
    // Families should also be associated with an institution at registration
    return this == AccountType.caregiver || this == AccountType.elder || this == AccountType.family;
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