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

class SkillSuggestion {
  const SkillSuggestion({
    required this.id,
    required this.name,
    required this.sources,
    this.because = '',
  });

  final String id;
  final String name;
  final List<String> sources;
  final String because;
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
