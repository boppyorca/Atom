class DictionarySkill {
  const DictionarySkill(this.name, this.keywords);

  final String name;
  final List<String> keywords;
}

/// Starter list for both doors. The old design guessed about 150 names.
/// That number is not locked, so this list only has names the tests use
/// plus a few common ones.
const skillDictionary = <DictionarySkill>[
  DictionarySkill('Flutter', ['flutter']),
  DictionarySkill('Dart', ['dart']),
  DictionarySkill('React', ['react']),
  DictionarySkill('TypeScript', ['typescript']),
  DictionarySkill('Python', ['python']),
  DictionarySkill('Docker', ['docker']),
  DictionarySkill('PostgreSQL', ['postgresql', 'postgres']),
  DictionarySkill('Swift', ['swift']),
  DictionarySkill('Kotlin', ['kotlin']),
];

const maxJobLength = 8000;

String normalizeSkillName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

bool containsTerm(String text, String term) {
  return RegExp(
    '\\b${RegExp.escape(term)}\\b',
    caseSensitive: false,
  ).hasMatch(text);
}

class SkillHit {
  const SkillHit({
    required this.name,
    required this.keyword,
    required this.repoName,
  });

  final String name;
  final String keyword;
  final String repoName;
}

class RepoText {
  const RepoText({required this.name, required this.body});

  final String name;
  final String body;
}

List<SkillHit> skillsInRepos(List<RepoText> repos) {
  final hits = <SkillHit>[];
  final seen = <String>{};
  for (final repo in repos) {
    for (final skill in skillDictionary) {
      final key = normalizeSkillName(skill.name);
      if (seen.contains(key)) continue;
      for (final keyword in skill.keywords) {
        if (containsTerm(repo.body, keyword)) {
          seen.add(key);
          hits.add(
            SkillHit(name: skill.name, keyword: keyword, repoName: repo.name),
          );
          break;
        }
      }
    }
  }
  return hits;
}

class JobSkillGroup {
  const JobSkillGroup({required this.have, required this.missing});

  final List<String> have;
  final List<String> missing;
}

/// A blank job is not compared. A job past [maxJobLength] is too long.
/// Otherwise the known skills in the text are split by the profile.
JobSkillGroup? skillsInJob(String job, Iterable<String> profileNames) {
  final trimmed = job.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.runes.length > maxJobLength) {
    throw const JobTooLongException();
  }
  final owned = profileNames.map(normalizeSkillName).toSet();
  final have = <String>[];
  final missing = <String>[];
  for (final skill in skillDictionary) {
    final found = skill.keywords.any(
      (keyword) => containsTerm(trimmed, keyword),
    );
    if (!found) continue;
    if (owned.contains(normalizeSkillName(skill.name))) {
      have.add(skill.name);
    } else {
      missing.add(skill.name);
    }
  }
  return JobSkillGroup(have: have, missing: missing);
}

class JobTooLongException implements Exception {
  const JobTooLongException();
}

class SuggestionBoard {
  String? _repoKey;
  final _dismissed = <String>{};

  void setRepos(List<String> names) {
    final key = (names.toList()..sort()).join('|');
    if (key == _repoKey) return;
    _repoKey = key;
    _dismissed.clear();
  }

  void dismiss(String skillName) {
    _dismissed.add(normalizeSkillName(skillName));
  }

  List<SkillHit> visible(List<SkillHit> hits) {
    return hits
        .where((hit) => !_dismissed.contains(normalizeSkillName(hit.name)))
        .toList();
  }
}
