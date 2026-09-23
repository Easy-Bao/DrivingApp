import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/active_ride/domain/entities/accepted_booking.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_session_request.dart';

abstract interface class BookingRepository() {
  Future<Result<String, Failure>> createSession(BookingSessionRequest request);

  Future<Result<List<BookingOffer>, Failure>> fetchOffers(String sessionId);

  Future<Result<AcceptedBooking, Failure>> acceptOffer({
    required String sessionId,
    required String offerId,
  });

  Future<Result<void, Failure>> cancelSession(String sessionId);
}

extension BookingRepositoryResultApi on BookingRepository {
  Future<Result<String, DomainFailure>> createSessionResult(
    BookingSessionRequest request,
  ) => _captureBookingResult(() => createSession(request));

  Future<Result<List<BookingOffer>, DomainFailure>> fetchOffersResult(
    String sessionId,
  ) => _captureBookingResult(() => fetchOffers(sessionId));

  Future<Result<AcceptedBooking, DomainFailure>> acceptOfferResult({
    required String sessionId,
    required String offerId,
  }) => _captureBookingResult(
    () => acceptOffer(sessionId: sessionId, offerId: offerId),
  );

  Future<Result<void, DomainFailure>> cancelSessionResult(String sessionId) =>
      _captureBookingResult(() => cancelSession(sessionId));
}

Future<Result<T, DomainFailure>> _captureBookingResult<T>(
  Future<Result<T, Failure>> Function() operation,
) async {
  try {
    final result = await operation();
    final Result<T, DomainFailure> converted = result
        .fold<Result<T, DomainFailure>>(
          (failure) => Err<T, DomainFailure>(failure),
          (value) => Ok<T, DomainFailure>(value),
        );
    return converted;
  } catch (error) {
    return Err<T, DomainFailure>(
      FailureMapper.fromException(
        error,
        serverMessage: 'Booking services are temporarily unavailable.',
      ),
    );
  }
}
