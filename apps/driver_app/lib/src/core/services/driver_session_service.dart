import 'package:session_service/session_service.dart';
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

  DriverSessionService({
    required SecureSessionService secureSessionService,
  }) : _secureSessionService = secureSessionService;

  Future<DriverProfile?> getProfile() async {
    final driverId = await _secureSessionService.readDriverId();
    if (driverId == null || driverId.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('driver_name') ?? 'Driver';
    final email = prefs.getString('driver_email') ?? '';
    final vehicleType = prefs.getString('vehicle_type') ?? 'Bao Bao';
    final plateNumber = prefs.getString('plate_number') ?? 'ABC 1234';
    final rating = prefs.getString('rating') ?? '5.0';

    return DriverProfile(
      id: driverId,
      name: name,
      email: email,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      rating: rating,
    );
  }

  Future<void> saveProfile(DriverProfile profile) async {
    await _secureSessionService.writeDriverId(profile.id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_name', profile.name);
    await prefs.setString('driver_email', profile.email);
    await prefs.setString('vehicle_type', profile.vehicleType);
    await prefs.setString('plate_number', profile.plateNumber);
    await prefs.setString('rating', profile.rating);
  }
}
