class MockReportedPerson {
  const MockReportedPerson({
    required this.id,
    required this.name,
    this.phone = '',
    this.institute = '',
    this.imageAsset,
  });

  final String id;
  final String name;
  final String phone;
  final String institute;
  final String? imageAsset;
}

enum ReportKind {
  personal,
  thirdParty,
}

enum OffenderKind {
  relative,
  caregiver,
  institution,
}

class ReportDraft {
  const ReportDraft({
    this.kind,
    this.description = '',
    this.isRecent = false,
    this.happenedBefore = true,
    this.offender,
    this.person,
    this.otherName = '',
    this.otherPhone = '',
    this.otherInstitute = '',
  });

  final ReportKind? kind;
  final String description;
  final bool isRecent;
  final bool happenedBefore;
  final OffenderKind? offender;
  final MockReportedPerson? person;
  final String otherName;
  final String otherPhone;
  final String otherInstitute;

  static ReportDraft fromExtra(Object? extra) {
    return extra is ReportDraft ? extra : const ReportDraft();
  }

  ReportDraft copyWith({
    ReportKind? kind,
    String? description,
    bool? isRecent,
    bool? happenedBefore,
    OffenderKind? offender,
    MockReportedPerson? person,
    bool clearPerson = false,
    String? otherName,
    String? otherPhone,
    String? otherInstitute,
  }) {
    return ReportDraft(
      kind: kind ?? this.kind,
      description: description ?? this.description,
      isRecent: isRecent ?? this.isRecent,
      happenedBefore: happenedBefore ?? this.happenedBefore,
      offender: offender ?? this.offender,
      person: clearPerson ? null : (person ?? this.person),
      otherName: otherName ?? this.otherName,
      otherPhone: otherPhone ?? this.otherPhone,
      otherInstitute: otherInstitute ?? this.otherInstitute,
    );
  }
}

class MockReportData {
  MockReportData._();

  static const caregivers = [
    MockReportedPerson(
      id: 'caregiver-1',
      name: 'Isabelle Guimarães',
      phone: '(11) 98888-0101',
      institute: 'Lar Conviva',
    ),
  ];

  static const relatives = [
    MockReportedPerson(
      id: 'relative-1',
      name: 'Carlos Oliveira',
      phone: '(11) 97777-2020',
      institute: 'Família',
    ),
  ];

  static const institution = MockReportedPerson(
    id: 'institution-1',
    name: 'Lar Conviva',
    institute: 'Lar Conviva',
  );
}
