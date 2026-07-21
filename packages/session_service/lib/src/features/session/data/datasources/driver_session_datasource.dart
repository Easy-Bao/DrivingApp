import 'package:session_service/src/features/session/data/datasources/secure_session_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProfile {
  final String id;
  final String name;
  final String email;
  final String vehicleType;
  final String plateNumber;
  final String rating;

  const DriverProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.vehicleType,
    required this.plateNumber,
    required this.rating,
  });
}

class DriverSessionException implements Exception {
  final String message;
  const DriverSessionException(this.message);

  @override
  String toString() => 'DriverSessionException: $message';
}

class DriverSessionService {
  final SecureSessionService _secureSessionService;
  final SharedPreferences _prefs;

  DriverSessionService({
    required SecureSessionService secureSessionService,
    required SharedPreferences prefs,
  })  : _secureSessionService = secureSessionService,
        _prefs = prefs;

  Future<DriverProfile?> getProfile() async {
    final driverId = await _secureSessionService.readDriverId();
    if (driverId == null || driverId.isEmpty) return null;

    final name = _prefs.getString('driver_name');
    final email = _prefs.getString('driver_email');
    final vehicleType = _prefs.getString('vehicle_type');
    final plateNumber = _prefs.getString('plate_number');
    final rating = _prefs.getString('rating');

    if (name == null || vehicleType == null || plateNumber == null) {
      return null;
    }

    return DriverProfile(
      id: driverId,
      name: name,
      email: email ?? '',
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      rating: rating ?? '5.0',
    );
  }

  Future<void> saveProfile(DriverProfile profile) async {
    await _secureSessionService.writeDriverId(profile.id);

    await Future.wait([
      _prefs.setString('driver_name', profile.name),
      _prefs.setString('driver_email', profile.email),
      _prefs.setString('vehicle_type', profile.vehicleType),
      _prefs.setString('plate_number', profile.plateNumber),
      _prefs.setString('rating', profile.rating),
    ]);
  }

  Future<void> clearSession() async {
    await _secureSessionService.deleteDriverId();
    await Future.wait([
      _prefs.remove('driver_name'),
      _prefs.remove('driver_email'),
      _prefs.remove('vehicle_type'),
      _prefs.remove('plate_number'),
      _prefs.remove('rating'),
    ]);
  }
}
