import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BidSessionTrip {
  const BidSessionTrip({
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.pickupAddress,
  });

  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? pickupAddress;
}

class DriverMatchResult {
  const DriverMatchResult({
    required this.trip,
    required this.driverName,
    required this.fare,
    required this.driverRating,
    required this.vehicleType,
    required this.plateNumber,
  });

  final BidSessionTrip trip;
  final String driverName;
  final double fare;
  final String driverRating;
  final String vehicleType;
  final String plateNumber;

  Map<String, dynamic> toNavigationExtra() {
    return {
      'rideType': trip.rideType,
      'fare': fare,
      'destination': trip.destination,
      'distance': trip.distance,
      'duration': trip.duration,
      'driverName': driverName,
      'driverRating': driverRating,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'pickupAddress': trip.pickupAddress ?? 'Current Location',
    };
  }
}

class BidSessionService {
  final PassengerApiService _apiService;

  BidSessionService({required PassengerApiService apiService})
    : _apiService = apiService;

  String? _sessionId;
  BidSessionTrip? _trip;
  List<dynamic> _offers = [];
  Timer? _pollTimer;
  bool _isBackgrounded = false;
  bool _isForeground = false;

  final StreamController<List<dynamic>> _offersController =
      StreamController<List<dynamic>>.broadcast();
  final StreamController<DriverMatchResult> _driverFoundController =
      StreamController<DriverMatchResult>.broadcast();
  final StreamController<void> _statusController =
      StreamController<void>.broadcast();

  Stream<List<dynamic>> get offersStream => _offersController.stream;
  Stream<DriverMatchResult> get driverFoundStream =>
      _driverFoundController.stream;
  Stream<void> get statusStream => _statusController.stream;

  String? get sessionId => _sessionId;
  BidSessionTrip? get trip => _trip;
  List<dynamic> get offers => List.unmodifiable(_offers);
  bool get isActive => _sessionId != null;
  bool get isBackgrounded => _isBackgrounded;
  bool get isForeground => _isForeground;

  void setForeground(bool value) {
    _isForeground = value;
    if (value) {
      _isBackgrounded = false;
    }
    _notifyStatus();
  }

  void backgroundSearch() {
    _isBackgrounded = true;
    _isForeground = false;
    _notifyStatus();
  }

  Future<void> startSession({
    required BidSessionTrip trip,
    required String passengerId,
    required double pickupLat,
    required double pickupLng,
    required double distanceKm,
    required double durationMinutes,
    String? targetDriverId,
  }) async {
    await cancelSession(notify: false);

    final result = await _apiService.openBidSession(
      passengerId: passengerId,
      rideType: trip.rideType,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupName: trip.pickupAddress ?? 'Current Location',
      dropoffLat: trip.destination.latitude,
      dropoffLng: trip.destination.longitude,
      dropoffName: trip.destination.name,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      targetDriverId: targetDriverId,
    );

    if (result == null || result['id'] == null) {
      return;
    }

    _sessionId = result['id'] as String;
    _trip = trip;
    _offers = [];
    _isBackgrounded = false;
    _notifyStatus();
    _startPolling();
  }

  Future<void> acceptOffer({
    required String offerId,
    required String driverName,
    required String vehicleType,
    required String plateNumber,
    required double proposedFare,
  }) async {
    if (_sessionId == null || _trip == null) {
      return;
    }

    final acceptResult = await _apiService.acceptBidOffer(
      sessionId: _sessionId!,
      offerId: offerId,
    );

    if (acceptResult == null || acceptResult['ride_id'] == null) {
      return;
    }

    _pollTimer?.cancel();
    final rideId = acceptResult['ride_id'] as String;
    final sharedPreferencesInstance = await SharedPreferences.getInstance();
    await sharedPreferencesInstance.setString('active_ride_id', rideId);

    final result = DriverMatchResult(
      trip: _trip!,
      driverName: driverName,
      fare: proposedFare,
      driverRating: '5.0',
      vehicleType: vehicleType,
      plateNumber: plateNumber,
    );

    _clearSessionState(notify: false);
    _driverFoundController.add(result);
  }

  Future<void> cancelSession({bool notify = true}) async {
    _pollTimer?.cancel();
    if (_sessionId != null) {
      try {
        await _apiService.cancelBidSession(_sessionId!);
      } catch (error) {
        // Absorb remote cancellation failure so that local state teardown 
        // is never blocked by temporary network outages or server exceptions, 
        // allowing the passenger to successfully cancel locally and exit the search view.
      }
    }
    _clearSessionState(notify: notify);
  }

  void dispose() {
    _pollTimer?.cancel();
    unawaited(_offersController.close());
    unawaited(_driverFoundController.close());
    unawaited(_statusController.close());
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final sessionId = _sessionId;
      if (sessionId == null) {
        timer.cancel();
        return;
      }

      final offers = await _apiService.pollBidOffers(sessionId);
      _offers = offers;
      _offersController.add(_offers);
      _notifyStatus();

      final statusData = await _apiService.getBidSession(sessionId);
      if (statusData == null || statusData['status'] != 'accepted') {
        return;
      }

      timer.cancel();
      final acceptedDriverId = statusData['accepted_driver_id'] as String?;
      final rideId = statusData['ride_id'] as String? ?? '';
      final offersList = statusData['offers'] as List<dynamic>? ?? [];
      final acceptedOffer = offersList.cast<Map<String, dynamic>?>().firstWhere(
        (option) => option?['driver_id'] == acceptedDriverId,
        orElse: () => null,
      );

      if (acceptedOffer == null || _trip == null) {
        _clearSessionState();
        return;
      }

      final sharedPreferencesInstance = await SharedPreferences.getInstance();
      await sharedPreferencesInstance.setString('active_ride_id', rideId);

      final result = DriverMatchResult(
        trip: _trip!,
        driverName: acceptedOffer['driver_name'] as String? ?? 'Driver',
        fare:
            (acceptedOffer['proposed_fare'] as num?)?.toDouble() ?? _trip!.fare,
        driverRating: '5.0',
        vehicleType: acceptedOffer['vehicle_type'] as String? ?? 'Bao Bao',
        plateNumber: acceptedOffer['plate_number'] as String? ?? 'Unknown',
      );

      _clearSessionState(notify: false);
      _driverFoundController.add(result);
    });
  }

  void _clearSessionState({bool notify = true}) {
    _sessionId = null;
    _trip = null;
    _offers = [];
    _isBackgrounded = false;
    _isForeground = false;
    if (notify) {
      _notifyStatus();
    }
  }

  void _notifyStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(null);
    }
  }
}
