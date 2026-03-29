import 'package:flutter_test/flutter_test.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/session/session_user.dart';

void main() {
  group('normalizeApiBaseUrl', () {
    test('appends the mobile API path when missing', () {
      expect(
        normalizeApiBaseUrl('https://example.com'),
        'https://example.com/api/mobile/v1',
      );
    });

    test('preserves the mobile API path when already present', () {
      expect(
        normalizeApiBaseUrl('https://example.com/api/mobile/v1/'),
        'https://example.com/api/mobile/v1',
      );
    });
  });

  group('MobileApiClient.resolveUrl', () {
    test('resolves relative paths against the active base URL', () {
      final client = MobileApiClient(
        baseUrl: 'https://example.com/api/mobile/v1',
      );

      expect(
        client.resolveUrl('/media/file.pdf'),
        'https://example.com/media/file.pdf',
      );
    });
  });

  group('SessionUser.fromJson', () {
    test('parses integer ids that arrive as strings', () {
      final user = SessionUser.fromJson({
        'id': '42',
        'username': 'owner',
        'display_name': 'Owner Name',
        'role': 'owner',
        'business': {'name': 'SkillBite'},
      });

      expect(user.id, 42);
      expect(user.username, 'owner');
      expect(user.displayName, 'Owner Name');
      expect(user.role, 'owner');
      expect(user.businessName, 'SkillBite');
    });
  });
}
