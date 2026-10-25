import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/domain/entities/accepted_booking.dart';
import 'package:passenger/src/features/booking/domain/entities/bid_session_snapshot.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_session_request.dart';

abstract interface class BookingRepository() {
  Future<Result<BidSessionSnapshot, Failure>> createSession(
    BookingSessionRequest request,
  );

  Future<Result<List<BookingOffer>, Failure>> fetchOffers(String sessionId);

  Future<Result<BidSessionSnapshot, Failure>> fetchSession(String sessionId);

  Future<Result<AcceptedBooking, Failure>> acceptOffer({
    required String sessionId,
    required String offerId,
  });

  Future<Result<void, Failure>> cancelSession(String sessionId);
}

extension BookingRepositoryResultApi on BookingRepository {
  Future<Result<BidSessionSnapshot, DomainFailure>> createSessionResult(
    BookingSessionRequest request,
  ) => captureResult(
    () => createSession(request),
    message: 'Booking services are temporarily unavailable.',
  );

  Future<Result<List<BookingOffer>, DomainFailure>> fetchOffersResult(
    String sessionId,
  ) => captureResult(
    () => fetchOffers(sessionId),
    message: 'Booking services are temporarily unavailable.',
  );

  Future<Result<BidSessionSnapshot, DomainFailure>> fetchSessionResult(
    String sessionId,
  ) => captureResult(
    () => fetchSession(sessionId),
    message: 'Booking services are temporarily unavailable.',
  );

  Future<Result<AcceptedBooking, DomainFailure>> acceptOfferResult({
    required String sessionId,
    required String offerId,
  }) => captureResult(
    () => acceptOffer(sessionId: sessionId, offerId: offerId),
    message: 'Booking services are temporarily unavailable.',
  );

  Future<Result<void, DomainFailure>> cancelSessionResult(String sessionId) =>
      captureResult(
        () => cancelSession(sessionId),
        message: 'Booking services are temporarily unavailable.',
      );
}
