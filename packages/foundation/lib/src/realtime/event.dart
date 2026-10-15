import 'package:equatable/equatable.dart';

const int realtimeEventVersion = 1;

enum RealtimeEventType {
  rideOfferCreated('ride.offer.created'),
  rideOfferUpdated('ride.offer.updated'),
  rideMatched('ride.matched'),
  rideStatusChanged('ride.status.changed'),
  driverLocationUpdated('driver.location.updated'),
  passengerLocationUpdated('passenger.location.updated'),
  chatMessageCreated('chat.message.created'),
  presenceUpdated('presence.updated');

  const RealtimeEventType(this.wireValue);

  final String wireValue;

  static RealtimeEventType fromWireValue(String value) {
    return RealtimeEventType.values.firstWhere(
      (eventType) => eventType.wireValue == value,
      orElse: () =>
          throw const FormatException('Unsupported realtime event type.'),
    );
  }
}

final class const RealtimeScope({
  this.rideId,
  this.roomId,
  this.driverId,
  this.passengerId,
  this.driverPool = false,
}) extends Equatable {
  final String? rideId;
  final String? roomId;
  final String? driverId;
  final String? passengerId;
  final bool driverPool;

  bool get isEmpty =>
      _isBlank(rideId) &&
      _isBlank(roomId) &&
      _isBlank(driverId) &&
      _isBlank(passengerId) &&
      !driverPool;

  factory fromJson(Map<String, dynamic> json) {
    final scope = RealtimeScope(
      rideId: _optionalIdentifier(json['ride_id'], 'ride_id'),
      roomId: _optionalIdentifier(json['room_id'], 'room_id'),
      driverId: _optionalIdentifier(json['driver_id'], 'driver_id'),
      passengerId: _optionalIdentifier(json['passenger_id'], 'passenger_id'),
      driverPool: json['driver_pool'] == true,
    );
    if (scope.isEmpty) {
      throw const FormatException('Realtime event scope is required.');
    }
    return scope;
  }

  Map<String, dynamic> toJson() => {
    if (rideId != null) 'ride_id': rideId,
    if (roomId != null) 'room_id': roomId,
    if (driverId != null) 'driver_id': driverId,
    if (passengerId != null) 'passenger_id': passengerId,
    if (driverPool) 'driver_pool': true,
  };

  @override
  List<Object?> get props => [
    rideId,
    roomId,
    driverId,
    passengerId,
    driverPool,
  ];
}

final class RealtimeEnvelope({
  required this.id,
  required this.type,
  required this.occurredAt,
  required this.scope,
  required Map<String, dynamic> payload,
  this.version = realtimeEventVersion,
}) extends Equatable {
  this : payload = Map.unmodifiable(payload) {
    _validate();
  }

  final String id;
  final int version;
  final RealtimeEventType type;
  final DateTime occurredAt;
  final RealtimeScope scope;
  final Map<String, dynamic> payload;

  factory fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    final rawScope = json['scope'];
    if (rawPayload is! Map || rawScope is! Map) {
      throw const FormatException(
        'Realtime event payload and scope must be JSON objects.',
      );
    }

    final version = json['version'];
    final occurredAt = DateTime.tryParse(json['occurred_at']?.toString() ?? '');
    if (version is! int || occurredAt == null) {
      throw const FormatException('Realtime event metadata is invalid.');
    }

    return RealtimeEnvelope(
      id: _requiredIdentifier(json['id'], 'id'),
      version: version,
      type: RealtimeEventType.fromWireValue(
        _requiredIdentifier(json['type'], 'type'),
      ),
      occurredAt: occurredAt.toUtc(),
      scope: RealtimeScope.fromJson(Map<String, dynamic>.from(rawScope)),
      payload: Map<String, dynamic>.from(rawPayload),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'type': type.wireValue,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'scope': scope.toJson(),
    'payload': payload,
  };

  void _validate() {
    _requiredIdentifier(id, 'id');
    if (version != realtimeEventVersion) {
      throw FormatException('Unsupported realtime event version: $version.');
    }
    if (occurredAt.isUtc == false) {
      throw const FormatException('Realtime event timestamp must be UTC.');
    }
    if (scope.isEmpty) {
      throw const FormatException('Realtime event scope is required.');
    }
  }

  @override
  List<Object?> get props => [id, version, type, occurredAt, scope, payload];
}

sealed class const RealtimeEvent(this.envelope) extends Equatable {
  final RealtimeEnvelope envelope;

  factory fromEnvelope(RealtimeEnvelope envelope) => switch (envelope.type) {
    RealtimeEventType.rideOfferCreated => RideOfferCreatedEvent(envelope),
    RealtimeEventType.rideOfferUpdated => RideOfferUpdatedEvent(envelope),
    RealtimeEventType.rideMatched => RideMatchedEvent(envelope),
    RealtimeEventType.rideStatusChanged => RideStatusChangedEvent(envelope),
    RealtimeEventType.driverLocationUpdated => DriverLocationUpdatedEvent(
      envelope,
    ),
    RealtimeEventType.passengerLocationUpdated => PassengerLocationUpdatedEvent(
      envelope,
    ),
    RealtimeEventType.chatMessageCreated => ChatMessageCreatedEvent(envelope),
    RealtimeEventType.presenceUpdated => PresenceUpdatedEvent(envelope),
  };

  @override
  List<Object?> get props => [envelope];
}

final class const RideOfferCreatedEvent(super.envelope) extends RealtimeEvent {}

final class const RideOfferUpdatedEvent(super.envelope) extends RealtimeEvent {}

final class const RideMatchedEvent(super.envelope) extends RealtimeEvent {}

final class const RideStatusChangedEvent(super.envelope)
    extends RealtimeEvent {}

final class const DriverLocationUpdatedEvent(super.envelope)
    extends RealtimeEvent {}

final class const PassengerLocationUpdatedEvent(super.envelope)
    extends RealtimeEvent {}

final class const ChatMessageCreatedEvent(super.envelope)
    extends RealtimeEvent {}

final class const PresenceUpdatedEvent(super.envelope) extends RealtimeEvent {}

String _requiredIdentifier(Object? value, String field) {
  final identifier = _optionalIdentifier(value, field);
  if (identifier == null) {
    throw FormatException('Realtime event $field is required.');
  }
  return identifier;
}

String? _optionalIdentifier(Object? value, String field) {
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Realtime event $field must be a string.');
  }
  if (_isBlank(value) || value.trim() != value || value.length > 128) {
    throw FormatException('Realtime event $field is invalid.');
  }
  return value;
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;
