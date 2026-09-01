import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/ride_history/data/data_sources/passenger_ride_history_remote_data_source.dart';
import 'package:passenger/src/features/ride_history/domain/entities/ride_history_overview.dart';
import 'package:passenger/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:foundation/foundation.dart';

const List<String> _monthAbbreviations = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _shortenAddress(String fullAddress) {
  final parts = fullAddress.split(',').map((p) => p.trim()).toList();
  if (parts.length >= 2) {
    return '${parts[parts.length - 2]}, ${parts.last}';
  }
  return fullAddress;
}

final class RideHistoryRepositoryImpl({
  required PassengerRideHistoryRemoteDataSource remoteDataSource,
}) implements RideHistoryRepository {
  final PassengerRideHistoryRemoteDataSource _remoteDataSource;

  this : _remoteDataSource = remoteDataSource;

  Failure _mapExceptionToFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return const AuthFailure(
          'Your session has ended. Sign in again to view activity.',
        );
      }
      return switch (error.type) {
        DioExceptionType.connectionError => const NetworkFailure(
          'Unable to connect. Check your connection and try again.',
        ),
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => const ServerFailure.withStatusCode(
          'Activity request timed out.',
          504,
        ),
        _ => ServerFailure.withStatusCode(
          'Activity is temporarily unavailable. Please try again.',
          statusCode ?? 500,
        ),
      };
    }
    if (error is ServerException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid request data.');
      }
      return ServerFailure.withStatusCode(
        'Activity is temporarily unavailable. Please try again.',
        error.statusCode,
      );
    }
    if (error is DataParsingException) {
      return const ValidationFailure('Activity data could not be read.');
    }
    if (error is CacheException) {
      return const CacheFailure('Unable to read saved activity data.');
    }
    return const ServerFailure(
      'Activity is temporarily unavailable. Please try again.',
    );
  }

  @override
  Future<Either<Failure, RideHistoryOverview>> fetchRideHistoryOverview(
    String passengerId, {
    int limit = 25,
  }) async {
    try {
      final pageFuture = _remoteDataSource.fetchRideHistory(
        passengerId,
        limit: limit,
        offset: 0,
      );
      final summaryFuture = _remoteDataSource.fetchSummary(passengerId);
      final rawPage = await pageFuture;
      final summary = await summaryFuture;
      return Right(
        RideHistoryOverview(
          rides: _mapPage(rawPage),
          weeklyFareCentavos: SafeParse.toInt(
            summary['this_week_fare_centavos'],
          ),
          weeklyRideCount: SafeParse.toInt(
            summary['this_week_completed_rides'],
          ),
        ),
      );
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, OffsetPage<RideHistory>>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final rawPage = await _remoteDataSource.fetchRideHistory(
        passengerId,
        limit: limit,
        offset: offset,
      );
      return Right(_mapPage(rawPage));
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  OffsetPage<RideHistory> _mapPage(OffsetPage<Map<String, dynamic>> rawPage) {
    return OffsetPage<RideHistory>(
      items: rawPage.items.map(_mapToModel).toList(growable: false),
      hasMore: rawPage.hasMore,
      nextOffset: rawPage.nextOffset,
    );
  }

  RideHistory _mapToModel(Map<String, dynamic> raw) {
    return RideHistory(
      id: SafeParse.toStringValue(raw['id']),
      pickup: _shortenAddress(SafeParse.toStringValue(raw['pickup_name'])),
      destination: _shortenAddress(
        SafeParse.toStringValue(raw['dropoff_name']),
      ),
      pickupLat: SafeParse.toDouble(raw['pickup_latitude']),
      pickupLng: SafeParse.toDouble(raw['pickup_longitude']),
      destLat: SafeParse.toDouble(raw['dropoff_latitude']),
      destLng: SafeParse.toDouble(raw['dropoff_longitude']),
      date: _formatCreatedAt(raw['completed_at'] ?? raw['created_at']),
      price: _formatPrice(raw['fare'], raw['fare_centavos']),
      status: SafeParse.toStringValue(raw['status'], 'unknown'),
      driverId: SafeParse.toStringValue(raw['driver_id']),
      driverName: _firstNonEmpty(raw['driver_name'], raw['driverName']),
      vehiclePlate: _firstNonEmpty(raw['plate_number'], raw['plateNumber']),
      vehicleType: _firstNonEmpty(raw['vehicle_type'], raw['vehicleType']),
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

  String _formatPrice(dynamic price, dynamic fareCentavos) {
    final fareDouble = price != null
        ? SafeParse.toDouble(price)
        : SafeParse.toDouble(fareCentavos) / 100;
    return formatPesoAmount(fareDouble);
  }

  String _firstNonEmpty(Object? primary, Object? fallback) {
    final primaryValue = SafeParse.toStringValue(primary).trim();
    if (primaryValue.isNotEmpty) return primaryValue;
    return SafeParse.toStringValue(fallback).trim();
  }
}
