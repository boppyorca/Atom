class GithubRepoPage {
  const GithubRepoPage({required this.connected, required this.repos});

  final bool connected;
  final List<GithubRepo> repos;
}

class GithubRepo {
  const GithubRepo({
    required this.fullName,
    required this.url,
    required this.isFork,
    required this.selected,
    this.description,
    this.pushedAt,
  });

  final String fullName;
  final String url;
  final String? description;
  final bool isFork;
  final bool selected;
  final DateTime? pushedAt;

  String get name => fullName.split('/').last;

  factory GithubRepo.fromJson(Map<String, dynamic> json) {
    return GithubRepo(
      fullName: json['full_name'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      isFork: json['is_fork'] as bool? ?? false,
      selected: json['selected'] as bool? ?? false,
      pushedAt: DateTime.tryParse(json['pushed_at'] as String? ?? ''),
    );
  }

  GithubRepo copyWith({bool? selected}) {
    return GithubRepo(
      fullName: fullName,
      url: url,
      description: description,
      isFork: isFork,
      selected: selected ?? this.selected,
      pushedAt: pushedAt,
    );
  }
}
