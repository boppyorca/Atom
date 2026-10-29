enum EvidenceKind { article, product }

class EvidenceLink {
  const EvidenceLink({
    required this.id,
    required this.kind,
    required this.url,
    required this.title,
  });

  factory EvidenceLink.fromJson(Map<String, dynamic> json) {
    return EvidenceLink(
      id: json['id'] as String,
      kind: EvidenceKind.values.byName(json['kind'] as String),
      url: json['url'] as String,
      title: json['title'] as String?,
    );
  }

  final String id;
  final EvidenceKind kind;
  final String url;
  final String? title;
}

final evidenceUrlPattern = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');

bool isValidEvidenceUrl(String url) {
  final trimmed = url.trim();
  return trimmed.length <= 2048 && evidenceUrlPattern.hasMatch(trimmed);
}
