enum ProfileVisibility { private, public }

enum ContactLinkType { email, linkedin }

class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    this.bio,
    this.cityId,
    this.contactType,
    this.contactValue,
    this.contactVisible = false,
    this.visibility = ProfileVisibility.private,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final contactType = json['contact_type'] as String?;
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      cityId: json['city_id'] as int?,
      contactType: contactType == null
          ? null
          : ContactLinkType.values.byName(contactType),
      contactValue: json['contact_value'] as String?,
      contactVisible: json['contact_visible'] as bool,
      visibility: ProfileVisibility.values.byName(json['visibility'] as String),
    );
  }

  static const maxBioLength = 300;
  static const maxDisplayNameLength = 60;

  final String id;
  final String displayName;
  final String? bio;
  final int? cityId;
  final ContactLinkType? contactType;
  final String? contactValue;
  final bool contactVisible;
  final ProfileVisibility visibility;

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'bio': bio,
    'city_id': cityId,
    'contact_type': contactType?.name,
    'contact_value': contactValue,
    'contact_visible': contactVisible,
    'visibility': visibility.name,
  };
}
