enum SkillConfidence {
  selfClaimed,
  evidenced,
  endorsed;

  static SkillConfidence parse(String value) {
    return switch (value) {
      'self_claimed' => selfClaimed,
      'evidenced' => evidenced,
      'endorsed' => endorsed,
      _ => throw FormatException('Unknown skill confidence: $value'),
    };
  }
}

class Skill {
  const Skill({required this.id, required this.name, required this.confidence});

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      confidence: SkillConfidence.parse(json['confidence'] as String),
    );
  }

  final String id;
  final String name;
  final SkillConfidence confidence;
}
