import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/activity_repository.dart';
import 'package:passenger_services/passenger_services.dart';

const _monthAbbreviations = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

String _shortenAddress(String fullAddress) {
  final parts = fullAddress.split(',').map((p) => p.trim()).toList();
  if (parts.length >= 2) {
    return '${parts[parts.length - 2]}, ${parts.last}';
  }
  return fullAddress;
}

class ActivityRepositoryImpl implements ActivityRepository {
  final PassengerApiService _apiService;

  ActivityRepositoryImpl({required PassengerApiService apiService})
    : _apiService = apiService;

  Failure _mapExceptionToFailure(Object error) {
    if (error is ServerException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid request data.');
      }
      return ServerFailure('Server returned status code ${error.statusCode}.');
    }
    if (error is DataParsingException) {
      return ValidationFailure(error.message);
    }
    if (error is CacheException) {
      return CacheFailure(error.message);
    }
    return ServerFailure('Unexpected system error: $error');
  }

  @override
  Future<Either<Failure, List<RideHistoryModel>>> fetchRideHistory(
    String passengerId,
  ) async {
    try {
      final rawList = await _apiService.fetchRideHistory(passengerId);
      return Right(
        rawList.map((raw) => _mapToModel(raw as Map<String, dynamic>)).toList(),
      );
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
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
      driverId: raw['driver_id'] as String? ?? '',
      driverName: raw['driver_name'] as String? ?? '',
      vehiclePlate: raw['plate_number'] as String? ?? '',
      vehicleType: raw['vehicle_type'] as String? ?? '',
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
