import 'package:driver/src/core/formatters/value_formatters.dart';
import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:foundation/foundation.dart';

bool isActiveTripStatus(Object? value) {
  return const {
    'assigned',
    'accepted',
    'arrived',
    'in_transit',
  }.contains(valueAsString(value));
}

String? resolvedOfferSessionIdFromUpdate(RideOfferUpdatedEvent event) {
  final payload = event.envelope.payload;
  final session = payload['session'];
  final sessionId =
      valueAsString(payload['session_id']) ??
      (session is Map ? valueAsString(session['id']) : null);
  final wasClosed =
      session is Map &&
      const {
        'cancelled',
        'canceled',
      }.contains(valueAsString(session['status'])?.toLowerCase());
  final reason = valueAsString(payload['reason']);
  if (reason == 'another_driver_selected' || wasClosed) {
    return sessionId;
  }
  return null;
}

({RideSnapshot snapshot, String? sessionId})? parseMatchedRideEvent(
  RideMatchedEvent event,
) {
  final rawRide = event.envelope.payload['ride'];
  if (rawRide is! Map) return null;

  final ride = Map<String, dynamic>.from(rawRide);
  final rideId = valueAsString(ride['id']) ?? event.envelope.scope.rideId;
  if (rideId == null) return null;

  final status = valueAsString(ride['status']) ?? 'accepted';
  if (!isActiveTripStatus(status)) return null;
  ride['id'] = rideId;
  ride['status'] = status;

  final payload = event.envelope.payload;
  final session = payload['session'];
  final offer = payload['offer'];
  final matchedSessionId =
      valueAsString(payload['session_id']) ??
      (session is Map ? valueAsString(session['id']) : null) ??
      (offer is Map ? valueAsString(offer['session_id']) : null);

  return (
    snapshot: RideSnapshot.fromJson(ride, fallbackId: rideId),
    sessionId: matchedSessionId,
  );
}

({RideStatus status, String? rideId})? parseRideStatusChangedEvent(
  RideStatusChangedEvent event,
) {
  final rawRide = event.envelope.payload['ride'];
  final ride = rawRide is Map ? Map<String, dynamic>.from(rawRide) : null;
  final status =
      valueAsString(ride?['status']) ??
      valueAsString(event.envelope.payload['status']);
  if (status == null) return null;

  return (
    status: RideStatus.fromString(status),
    rideId: event.envelope.scope.rideId ?? valueAsString(ride?['id']),
  );
}
