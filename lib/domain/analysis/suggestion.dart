String effectiveJobStatus({
  required String status,
  required DateTime deadline,
  required DateTime now,
}) {
  if ((status == 'queued' || status == 'running') && now.isAfter(deadline)) {
    return 'timed_out';
  }
  return status;
}

bool historyWasCutShort(Object? metrics) {
  if (metrics is! Map) return false;
  for (final value in metrics.values) {
    if (value is Map && value['scan_truncated'] == true) return true;
  }
  return false;
}

class SkillSuggestion {
  const SkillSuggestion({
    required this.id,
    required this.name,
    required this.sources,
    this.because = '',
    this.verifiability = '',
    this.historyPartial = false,
  });

  final String id;
  final String name;
  final List<String> sources;
  final String because;
  final String verifiability;
  final bool historyPartial;
}

class AnalysisJob {
  const AnalysisJob({
    required this.id,
    required this.status,
    required this.deadline,
    this.seenAt,
  });

  final String id;
  final String status;
  final DateTime deadline;
  final DateTime? seenAt;
}
