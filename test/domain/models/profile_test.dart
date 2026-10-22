import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harness_app/domain/models/city.dart';
import 'package:harness_app/domain/models/profile.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('Profile reads a filled profile row', () {
    final profile = Profile.fromJson(_fixture('profile'));

    expect(profile.id, '11111111-1111-1111-1111-111111111111');
    expect(profile.displayName, 'Minh');
    expect(profile.bio, 'Flutter dev ở TP. HCM');
    expect(profile.cityId, 2);
    expect(profile.contactType, ContactLinkType.linkedin);
    expect(profile.contactValue, 'https://www.linkedin.com/in/minh');
    expect(profile.contactVisible, isTrue);
    expect(profile.visibility, ProfileVisibility.private);
  });

  test('Profile reads a new profile row with empty fields', () {
    final profile = Profile.fromJson(_fixture('profile_new'));

    expect(profile.bio, isNull);
    expect(profile.cityId, isNull);
    expect(profile.contactType, isNull);
    expect(profile.contactValue, isNull);
    expect(profile.contactVisible, isFalse);
  });

  test('Profile writes back the same JSON', () {
    for (final name in ['profile', 'profile_new']) {
      final json = _fixture(name);
      expect(Profile.fromJson(json).toJson(), json, reason: name);
    }
  });

  test('City reads the fixed list row and picks the label by language', () {
    final city = City.fromJson(_fixture('city'));

    expect(city.id, 2);
    expect(city.code, 'hcm');
    expect(city.label('vi'), 'TP. Hồ Chí Minh');
    expect(city.label('en'), 'Ho Chi Minh City');
  });
}
