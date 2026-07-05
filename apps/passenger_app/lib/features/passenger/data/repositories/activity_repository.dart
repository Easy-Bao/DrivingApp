/// Activity Repository: defines contracts and maps backend JSON payloads to typed ride history records.
import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';

const _monthAbbreviations = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

abstract class ActivityRepository {
  Future<List<RideHistoryModel>> fetchRideHistory(String passengerId);
}

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

    final fareDouble = SafeParse.toDouble(raw['fare']);
    final fareFormatted = '₱${fareDouble.toStringAsFixed(2)}';

    return RideHistoryModel(
      id: raw['id'] as String? ?? '',
      pickup: raw['pickup_name'] as String? ?? '',
      destination: raw['dropoff_name'] as String? ?? '',
      pickupLat: SafeParse.toDouble(raw['pickup_latitude']),
      pickupLng: SafeParse.toDouble(raw['pickup_longitude']),
      destLat: SafeParse.toDouble(raw['dropoff_latitude']),
      destLng: SafeParse.toDouble(raw['dropoff_longitude']),
      date: formattedDate,
      price: fareFormatted,
      status: raw['status'] as String? ?? 'unknown',
      driverName: raw['driver_name'] as String? ?? '',
      vehiclePlate: raw['plate_number'] as String? ?? '',
    );
  }
}

class ActivityRepositoryException implements Exception {
  final String message;
  const ActivityRepositoryException(this.message);

  @override
  String toString() => 'ActivityRepositoryException: $message';
}
