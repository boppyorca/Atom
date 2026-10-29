class GapItem {
  const GapItem({
    required this.skill,
    this.confidence,
    this.suggestionVi,
    this.suggestionEn,
  });

  final String skill;
  final String? confidence;
  final String? suggestionVi;
  final String? suggestionEn;
}

class GapSnapshot {
  const GapSnapshot({
    required this.status,
    this.errorCode,
    this.have = const [],
    this.missing = const [],
  });

  final String status;
  final String? errorCode;
  final List<GapItem> have;
  final List<GapItem> missing;
}
