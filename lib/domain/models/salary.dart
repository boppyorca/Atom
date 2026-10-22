import 'package:harness_app/domain/models/profile.dart';

class SalaryRole {
  const SalaryRole({
    required this.id,
    required this.code,
    required this.labelVi,
    required this.labelEn,
  });

  factory SalaryRole.fromJson(Map<String, dynamic> json) => SalaryRole(
    id: json['id'] as int,
    code: json['code'] as String,
    labelVi: json['label_vi'] as String,
    labelEn: json['label_en'] as String,
  );

  final int id;
  final String code;
  final String labelVi;
  final String labelEn;

  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

class SalaryEntry {
  const SalaryEntry({
    required this.id,
    required this.roleId,
    required this.cityId,
    required this.seniority,
    required this.grossMonthlyVnd,
  });

  factory SalaryEntry.fromJson(Map<String, dynamic> json) => SalaryEntry(
    id: json['id'] as String,
    roleId: json['role_id'] as int,
    cityId: json['city_id'] as int,
    seniority: SeniorityLevel.values.byName(json['seniority'] as String),
    grossMonthlyVnd: json['gross_monthly_vnd'] as int,
  );

  final String id;
  final int roleId;
  final int cityId;
  final SeniorityLevel seniority;
  final int grossMonthlyVnd;
}

class SalaryAggregate {
  const SalaryAggregate.insufficient()
    : status = 'insufficient_data',
      p25 = null,
      median = null,
      p75 = null;

  const SalaryAggregate.ok({
    required this.p25,
    required this.median,
    required this.p75,
  }) : status = 'ok';

  factory SalaryAggregate.fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'ok') return const SalaryAggregate.insufficient();
    return SalaryAggregate.ok(
      p25: json['p25_vnd'] as int,
      median: json['median_vnd'] as int,
      p75: json['p75_vnd'] as int,
    );
  }

  final String status;
  final int? p25;
  final int? median;
  final int? p75;

  bool get insufficient => status != 'ok';
}

String formatVnd(int value) {
  final digits = value.toString();
  final marks = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    if (index > 0 && remaining % 3 == 0) marks.write('.');
    marks.write(digits[index]);
  }
  return marks.toString();
}
