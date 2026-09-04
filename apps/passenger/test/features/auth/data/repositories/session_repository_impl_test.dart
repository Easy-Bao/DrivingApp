import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/data/repositories/session_repository_impl.dart';
import 'package:passenger/src/features/auth/domain/entities/passenger_session.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  test('clears cached identity values with the secure session', () async {
    SharedPreferences.setMockInitialValues({
      'passenger_name': 'Old Passenger',
      'passenger_email': 'old@example.com',
      'passenger_phone': '+639170000001',
      'passenger_address': 'Old address',
      'passenger_gender': 'Female',
      'passenger_avatar_path': '/tmp/old-avatar.png',
    });
    final preferences = await SharedPreferences.getInstance();
    final storage = MockFlutterSecureStorage();
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    final repository = SessionRepositoryImpl(
      secureSessionService: PassengerSessionStore(storage: storage),
      preferences: preferences,
    );

    final result = await repository.clearSession();

    expect(result, const Right(PassengerSession.guest()));
    for (final key in const [
      'passenger_name',
      'passenger_email',
      'passenger_phone',
      'passenger_address',
      'passenger_gender',
      'passenger_avatar_path',
    ]) {
      expect(preferences.containsKey(key), isFalse, reason: key);
    }
  });
}
