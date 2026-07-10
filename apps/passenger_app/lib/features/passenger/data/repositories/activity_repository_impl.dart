import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';
import 'package:passenger_app/features/passenger/data/repositories/activity_repository.dart';

const _monthAbbreviations = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

String _shortenAddress(String fullAddress) {
  final parts = fullAddress.split(',').map((p) => p.trim()).toList();
  if (parts.length >= 2) {
    return '${parts[parts.length - 2]}, ${parts.last}';
  }
  return fullAddress;
}

class ActivityRepositoryImpl implements ActivityRepository {
  @override
  Future<List<RideHistoryModel>> fetchRideHistory(String passengerId) async {
    try {
      final rawList = await PassengerApiService.fetchRideHistory(passengerId);
      return rawList
          .map((raw) => _mapToModel(raw as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('ActivityRepositoryImpl.fetchRideHistory failed: $error');
      throw ActivityRepositoryException('Failed to load ride history: $error');
    }
  }

  RideHistoryModel _mapToModel(Map<String, dynamic> raw) {
    return RideHistoryModel(
      id: raw['id'] as String? ?? '',
      pickup: _shortenAddress(raw['pickup_name'] as String? ?? ''),
      destination: _shortenAddress(raw['dropoff_name'] as String? ?? ''),
      pickupLat: SafeParse.toDouble(raw['pickup_latitude']),
      pickupLng: SafeParse.toDouble(raw['pickup_longitude']),
      destLat: SafeParse.toDouble(raw['dropoff_latitude']),
      destLng: SafeParse.toDouble(raw['dropoff_longitude']),
      date: _formatCreatedAt(raw['created_at']),
      price: _formatPrice(raw['fare']),
      status: raw['status'] as String? ?? 'unknown',
      driverName: raw['driver_name'] as String? ?? '',
      vehiclePlate: raw['plate_number'] as String? ?? '',
    );
  }

  String _formatCreatedAt(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '${_monthAbbreviations[dt.month - 1]} ${dt.day}, $hour:$min $ampm';
    } catch (_) {
      return createdAt.toString();
    }
  }

  String _formatPrice(dynamic price) {
    final fareDouble = SafeParse.toDouble(price);
    return '₱${fareDouble.toStringAsFixed(2)}';
  }
}
