class City {
  const City({
    required this.id,
    required this.code,
    required this.labelVi,
    required this.labelEn,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
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
