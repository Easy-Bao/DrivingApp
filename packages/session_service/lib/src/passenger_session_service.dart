import 'package:session_service/src/secure_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerProfile {
  final String id;
  final String name;
  final String email;
  final String phone;

  const PassengerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });
}

class PassengerSessionException implements Exception {
  final String message;
  const PassengerSessionException(this.message);

  @override
  String toString() => 'PassengerSessionException: $message';
}

class PassengerSessionService {
  final SecureSessionService _secureSessionService;
  final SharedPreferences _prefs;

  PassengerSessionService({
    required SecureSessionService secureSessionService,
    required SharedPreferences prefs,
  })  : _secureSessionService = secureSessionService,
        _prefs = prefs;

  Future<PassengerProfile?> getProfile() async {
    final passengerId = await _secureSessionService.readPassengerId();
    if (passengerId == null || passengerId.isEmpty) return null;

    final name = _prefs.getString('passenger_name');
    final email = _prefs.getString('passenger_email');
    final phone = _prefs.getString('passenger_phone');

    if (name == null || phone == null) {
      return null;
    }

    return PassengerProfile(
      id: passengerId,
      name: name,
      email: email ?? '',
      phone: phone,
    );
  }

  Future<void> saveProfile(PassengerProfile profile) async {
    await _secureSessionService.writePassengerId(profile.id);

    await Future.wait([
      _prefs.setString('passenger_name', profile.name),
      _prefs.setString('passenger_email', profile.email),
      _prefs.setString('passenger_phone', profile.phone),
    ]);
  }

  Future<void> clearSession() async {
    await _secureSessionService.deletePassengerId();
    await _secureSessionService.deleteAuthToken();
    await Future.wait([
      _prefs.remove('passenger_name'),
      _prefs.remove('passenger_email'),
      _prefs.remove('passenger_phone'),
    ]);
  }
}
