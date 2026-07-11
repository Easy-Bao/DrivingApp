import 'package:driver_app/src/core/services/driver_api_service.dart';
import 'package:driver_app/src/features/driver_dispatch/domain/repositories/driver_activity_repository.dart';

/**
 * Concrete implementation of [DriverActivityRepository] interfacing with the
 * backend API service.
 */
class DriverActivityRepositoryImpl implements DriverActivityRepository {
  @override
  Future<List<dynamic>> fetchTripHistory(String driverId) async {
    try {
      return await DriverApiService.fetchTripHistory(driverId);
    } catch (error) {
      throw Exception('Failed to load driver trip history: $error');
    }
  }
}
