import 'driver_activity_repository.dart';
import 'package:driver_app/src/core/services/driver_api_service.dart';

class DriverActivityRepositoryImpl implements DriverActivityRepository {
  @override
  Future<List<dynamic>> fetchTripHistory(String driverId) async {
    return DriverApiService.fetchTripHistory(driverId);
  }
}
