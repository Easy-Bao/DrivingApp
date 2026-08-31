import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/active_ride/domain/entities/accepted_booking.dart';
import 'package:passenger_app/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger_app/src/features/booking/domain/entities/booking_session_request.dart';
import 'package:foundation/foundation.dart';

abstract class IBookingRepository {
  Future<Either<Failure, String>> createSession(BookingSessionRequest request);

  Future<Either<Failure, List<BookingOffer>>> fetchOffers(String sessionId);

  Future<Either<Failure, AcceptedBooking>> acceptOffer({
    required String sessionId,
    required String offerId,
  });

  Future<Either<Failure, void>> cancelSession(String sessionId);
}
