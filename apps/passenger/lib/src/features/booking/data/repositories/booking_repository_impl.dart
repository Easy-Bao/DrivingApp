import 'package:core_domain/core_domain.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/data/datasources/booking_remote_data_source.dart';
import 'package:passenger/src/features/booking/data/repositories/booking_failure_mapper.dart';
import 'package:passenger/src/features/booking/domain/entities/accepted_booking.dart';
import 'package:passenger/src/features/booking/domain/entities/bid_session_snapshot.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_session_request.dart';
import 'package:passenger/src/features/booking/domain/repositories/booking_repository.dart';

final class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({required this._dataSource});

  final BookingRemoteDataSource _dataSource;

  @override
  Future<Result<BidSessionSnapshot, Failure>> createSession(
    BookingSessionRequest request,
  ) async {
    if (!request.isValid) {
      return const Err(ValidationFailure('The booking request is invalid.'));
    }
    try {
      final response = await _dataSource.createSession(
        request.toJson(),
        idempotencyKey: request.idempotencyKey,
      );
      final session = BidSessionSnapshot.fromJson(response);
      final sessionId = session.id;
      if (sessionId.isEmpty) {
        return const Err(
          ServerFailure('The booking response has no session ID.'),
        );
      }
      return Ok(session);
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }

  @override
  Future<Result<List<BookingOffer>, Failure>> fetchOffers(
    String sessionId,
  ) async {
    try {
      final rawOffers = await _dataSource.fetchOffers(sessionId);
      return Ok(
        rawOffers
            .map(BookingOffer.tryParse)
            .whereType<BookingOffer>()
            .toList(growable: false),
      );
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }

  @override
  Future<Result<BidSessionSnapshot, Failure>> fetchSession(
    String sessionId,
  ) async {
    try {
      final session = BidSessionSnapshot.fromJson(
        await _dataSource.fetchSession(sessionId),
      );
      if (session.id.isEmpty || session.status.isEmpty) {
        return const Err(
          ValidationFailure('The booking status response is incomplete.'),
        );
      }
      return Ok(session);
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }

  @override
  Future<Result<AcceptedBooking, Failure>> acceptOffer({
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
      final rideId = RideId.tryParse(
        SafeParse.toStringValue(response['ride_id'] ?? ride['id']),
      );
      if (rideId == null) {
        return const Err(
          ValidationFailure('The accepted offer has no ride ID.'),
        );
      }
      final fare = SafeParse.toNullableDouble(ride['fare_amount']);
      return Ok(
        AcceptedBooking(rideId: rideId.normalized, fareAmount: fare?.round()),
      );
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> cancelSession(String sessionId) async {
    try {
      final canceled = await _dataSource.cancelSession(sessionId);
      return canceled
          ? const Ok(null)
          : const Err(ServerFailure('The booking was not canceled.'));
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }
}

Failure _mapFailure(Object error) => mapBookingFailure(
  error,
  permissionMessage: 'You do not have permission to manage this booking.',
  timeoutMessage: 'Booking request timed out.',
  networkMessage: 'Unable to reach booking services. Check your connection.',
  serverMessage: 'Booking services are temporarily unavailable.',
  validationFailure: const ValidationFailure(
    'The booking request was rejected.',
  ),
  conflictMessage: 'The request is already being processed. Please retry.',
  parsingMessage: 'The booking response is invalid.',
);
