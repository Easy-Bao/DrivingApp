import 'package:passenger_app/src/features/auth/domain/failures/auth_failures.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/booking_remote_data_source.dart';
import 'package:passenger_app/src/features/active_ride/domain/entities/accepted_booking.dart';
import 'package:passenger_app/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger_app/src/features/booking/domain/entities/booking_session_request.dart';
import 'package:passenger_app/src/features/booking/domain/repositories/booking_repository.dart';
import 'package:foundation/foundation.dart';

final class BookingRepositoryImpl({required BookingRemoteDataSource dataSource})
    implements BookingRepository {
  this : _dataSource = dataSource;

  final BookingRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, String>> createSession(
    BookingSessionRequest request,
  ) async {
    if (!_validRequest(request)) {
      return const Left(ValidationFailure('The booking request is invalid.'));
    }
    try {
      final response = await _dataSource.createSession({
        'ride_type': request.rideType,
        'pickup_latitude': request.pickupLatitude,
        'pickup_longitude': request.pickupLongitude,
        'pickup_name': request.pickupName,
        'dropoff_latitude': request.dropoffLatitude,
        'dropoff_longitude': request.dropoffLongitude,
        'dropoff_name': request.dropoffName,
        'distance_km': request.distanceKm,
        'duration_minutes': request.durationMinutes,
        'target_driver_id': ?request.targetDriverId,
        'custom_fare_centavos': request.customFareCentavos,
        'passenger_note': request.passengerNote,
      });
      final sessionId = SafeParse.toStringValue(response['id']).trim();
      if (sessionId.isEmpty) {
        return const Left(
          ValidationFailure('The booking response has no session ID.'),
        );
      }
      return Right(sessionId);
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<BookingOffer>>> fetchOffers(
    String sessionId,
  ) async {
    try {
      final rawOffers = await _dataSource.fetchOffers(sessionId);
      return Right(
        rawOffers
            .map(BookingOffer.tryParse)
            .whereType<BookingOffer>()
            .toList(growable: false),
      );
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, AcceptedBooking>> acceptOffer({
    required String sessionId,
    required String offerId,
  }) async {
    try {
      final response = await _dataSource.acceptOffer(
        sessionId: sessionId,
        offerId: offerId,
      );
      final nested = response['ride'];
      final ride = nested is Map
          ? Map<String, dynamic>.from(nested)
          : const <String, dynamic>{};
      final rideId = SafeParse.toStringValue(response['ride_id'] ?? ride['id'])
          .trim();
      if (rideId.isEmpty) {
        return const Left(
          ValidationFailure('The accepted offer has no ride ID.'),
        );
      }
      final fare = SafeParse.toNullableDouble(ride['fare_centavos']);
      return Right(
        AcceptedBooking(rideId: rideId, fareCentavos: fare?.round()),
      );
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSession(String sessionId) async {
    try {
      final canceled = await _dataSource.cancelSession(sessionId);
      return canceled
          ? const Right(null)
          : const Left(ServerFailure('The booking was not canceled.'));
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }
}

bool _validRequest(BookingSessionRequest request) {
  return request.rideType.trim().isNotEmpty &&
      _validCoordinate(request.pickupLatitude, request.pickupLongitude) &&
      _validCoordinate(request.dropoffLatitude, request.dropoffLongitude) &&
      request.distanceKm.isFinite &&
      request.distanceKm > 0 &&
      request.durationMinutes.isFinite &&
      request.durationMinutes > 0 &&
      request.customFareCentavos > 0;
}

bool _validCoordinate(double latitude, double longitude) {
  return latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

Failure _mapFailure(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const AuthFailure(
        'Your passenger session has ended. Sign in again.',
      );
    }
    if (statusCode == 400 || statusCode == 409 || statusCode == 422) {
      return const ValidationFailure('The booking request was rejected.');
    }
    if (statusCode == null) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const ServerFailure.withStatusCode(
          'Booking request timed out.',
          504,
        );
      }
      return const NetworkFailure(
        'Unable to reach booking services. Check your connection.',
      );
    }
    return ServerFailure.withStatusCode(
      'Booking services are temporarily unavailable.',
      statusCode,
    );
  }
  if (error is ServerException) {
    return FailureMapper.fromException(
      error,
      serverMessage: 'Booking services are temporarily unavailable.',
    );
  }
  if (error is FormatException || error is DataParsingException) {
    return const ValidationFailure('The booking response is invalid.');
  }
  return const ServerFailure('Booking services are temporarily unavailable.');
}
