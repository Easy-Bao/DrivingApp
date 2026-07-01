import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';

// Month abbreviations for ISO-8601 date formatting without the intl package.
const _monthAbbreviations = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

/**
 * Abstract contract for loading a passenger's ride activity history.
 *
 * Decouples the ActivityBloc from the concrete data source so that mock,
 * fixture, or live-API implementations are swappable via GetIt without
 * touching any state-management code.
 */
abstract class ActivityRepository {
  /// Fetches all rides for [passengerId], sorted newest-first.
  Future<List<RideHistoryModel>> fetchRideHistory(String passengerId);
}

/**
 * API-backed implementation of [ActivityRepository].
 *
 * Calls `GET /passengers/:id/rides` on the passenger-service, then maps
 * the raw snake_case JSON into typed [RideHistoryModel] domain objects.
 * Any network or parsing failure is caught and rethrown as a clean
 * [ActivityRepositoryException], keeping error handling consistent at the
 * BLoC boundary.
 */
class ApiActivityRepository implements ActivityRepository {
  @override
  Future<List<RideHistoryModel>> fetchRideHistory(String passengerId) async {
    try {
      final rawList = await PassengerApiService.fetchRideHistory(passengerId);
      return rawList
          .map((raw) => _mapToModel(raw as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ApiActivityRepository.fetchRideHistory failed: $e');
      throw ActivityRepositoryException('Failed to load ride history: $e');
    }
  }

  /**
   * Maps raw JSON from `GET /passengers/:id/rides` to a [RideHistoryModel].
   *
   * The passenger-service returns dates as ISO-8601 strings. We format them
   * as a human-readable "MMM D, HH:MM AM/PM" string to keep the UI layer clean.
   * Fare is stored as a double on the server and formatted as ₱X.XX here.
   */
  RideHistoryModel _mapToModel(Map<String, dynamic> raw) {
    final createdAt = raw['created_at'];
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt.toString()).toLocal();
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final min = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour < 12 ? 'AM' : 'PM';
        formattedDate =
            '${_monthAbbreviations[dt.month - 1]} ${dt.day}, $hour:$min $ampm';
      } catch (_) {
        formattedDate = createdAt.toString();
      }
    }

    final fareRaw = raw['fare'];
    final fareDouble = fareRaw is num ? fareRaw.toDouble() : 0.0;
    final fareFormatted = '₱${fareDouble.toStringAsFixed(2)}';

    return RideHistoryModel(
      id: raw['id'] as String? ?? '',
      pickup: raw['pickup_name'] as String? ?? '',
      destination: raw['dropoff_name'] as String? ?? '',
      pickupLat: (raw['pickup_latitude'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (raw['pickup_longitude'] as num?)?.toDouble() ?? 0.0,
      destLat: (raw['dropoff_latitude'] as num?)?.toDouble() ?? 0.0,
      destLng: (raw['dropoff_longitude'] as num?)?.toDouble() ?? 0.0,
      date: formattedDate,
      price: fareFormatted,
      status: raw['status'] as String? ?? 'unknown',
      driverName: raw['driver_name'] as String? ?? '',
      vehiclePlate: raw['plate_number'] as String? ?? '',
    );
  }
}

/// Thrown when the activity data layer fails to load or parse ride history.
class ActivityRepositoryException implements Exception {
  final String message;
  const ActivityRepositoryException(this.message);

  @override
  String toString() => 'ActivityRepositoryException: $message';
}
