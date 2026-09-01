import 'account_type.dart';

class UserSession {
  const UserSession({
    required this.uid,
    required this.name,
    required this.phone,
    required this.accountType,
    required this.institutionId,
    required this.status,
    this.email,
    this.elderLinkCode,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String phone;
  final AccountType accountType;
  final String institutionId;
  final String status;
  final String? email;
  final String? elderLinkCode;
  final String? photoUrl;

  factory UserSession.fromMap({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final accountType = switch (data['type']?.toString()) {
      'idoso' => AccountType.elder,
      'caregiver' => AccountType.caregiver,
      'family' => AccountType.family,
      _ => throw StateError('Tipo de conta inválido.'),
    };

    return UserSession(
      uid: uid,
      name: data['name']?.toString().trim() ?? '',
      phone: data['phone']?.toString().trim() ?? '',
      accountType: accountType,
      institutionId: data['institutionId']?.toString().trim() ?? '',
      status: data['status']?.toString().trim() ?? '',
      email: _optionalString(data['email']),
      elderLinkCode: _optionalString(data['elderLinkCode']),
      photoUrl: _optionalString(data['photoUrl']),
    );
  }

  static String? _optionalString(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  UserSession copyWith({
    String? name,
    String? phone,
    String? email,
    String? photoUrl,
  }) {
    return UserSession(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      accountType: accountType,
      institutionId: institutionId,
      status: status,
      email: email ?? this.email,
      elderLinkCode: elderLinkCode,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'name': name,
      'phone': phone,
      'type': switch (accountType) {
        AccountType.elder => 'idoso',
        AccountType.caregiver => 'caregiver',
        AccountType.family => 'family',
      },
      'institutionId': institutionId,
      'status': status,
      if (email != null) 'email': email,
      if (elderLinkCode != null) 'elderLinkCode': elderLinkCode,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
