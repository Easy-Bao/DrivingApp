import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:passenger_services/src/features/bidding/domain/entities/bid_session_trip.dart';
import 'package:passenger_services/src/features/bidding/domain/entities/driver_match_result.dart';
import 'package:passenger_services/src/features/bidding/domain/repositories/bidding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BidSessionService {
  final BiddingRepository _biddingRepository;

  BidSessionService({required BiddingRepository biddingRepository})
      : _biddingRepository = biddingRepository;

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

    final response = await _biddingRepository.openBidSession(
      passengerId: passengerId,
      rideType: trip.rideType,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupName: trip.pickupAddress ?? '',
      dropoffLat: trip.destination.latitude,
      dropoffLng: trip.destination.longitude,
      dropoffName: trip.destination.name,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      targetDriverId: targetDriverId,
    );

    response.fold(
      (failure) {
        debugPrint('BidSessionService.startSession failed: ${failure.message}');
      },
      (result) {
        if (result == null || result['id'] == null) {
          return;
        }

        _sessionId = result['id'] as String;
        _trip = trip;
        _offers = [];
        _isBackgrounded = false;
        _notifyStatus();
        _startPolling();
      },
    );
  }

  Future<void> acceptOffer({
    required String offerId,
    required String driverId,
    required String driverName,
    required String vehicleType,
    required String plateNumber,
    required double proposedFare,
  }) async {
    if (_sessionId == null || _trip == null) {
      return;
    }

    final acceptResult = await _biddingRepository.acceptBidOffer(
      sessionId: _sessionId!,
      offerId: offerId,
    );

    await acceptResult.fold(
      (failure) async {
        debugPrint('BidSessionService.acceptOffer failed: ${failure.message}');
      },
      (result) async {
        if (result == null || result['ride_id'] == null) {
          return;
        }

        _pollTimer?.cancel();
        final rideId = result['ride_id'] as String;
        final sharedPreferencesInstance = await SharedPreferences.getInstance();
        await sharedPreferencesInstance.setString('active_ride_id', rideId);

        final resultMatch = DriverMatchResult(
          trip: _trip!,
          driverId: driverId,
          driverName: driverName,
          fare: proposedFare,
          driverRating: null,
          vehicleType: vehicleType,
          plateNumber: plateNumber,
        );

        _clearSessionState(notify: false);
        _driverFoundController.add(resultMatch);
      },
    );
  }

  Future<void> cancelSession({bool notify = true}) async {
    _pollTimer?.cancel();
    if (_sessionId != null) {
      final result = await _biddingRepository.cancelBidSession(_sessionId!);
      result.fold(
        (failure) {
          debugPrint('BidSessionService.cancelSession failed remotely: ${failure.message}');
        },
        (_) {},
      );
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

      final offersResult = await _biddingRepository.pollBidOffers(sessionId);
      offersResult.fold(
        (failure) {
          debugPrint('BidSessionService pollBidOffers failed: ${failure.message}');
        },
        (offersList) {
          _offers = offersList;
          _offersController.add(_offers);
          _notifyStatus();
        },
      );

      final statusResult = await _biddingRepository.getBidSession(sessionId);
      await statusResult.fold(
        (failure) async {
          debugPrint('BidSessionService getBidSession failed: ${failure.message}');
        },
        (statusData) async {
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
            driverId: acceptedDriverId ?? '',
            driverName: acceptedOffer['driver_name'] as String? ?? 'Driver',
            fare:
                (acceptedOffer['proposed_fare'] as num?)?.toDouble() ?? _trip!.fare,
            driverRating: null,
            vehicleType: acceptedOffer['vehicle_type'] as String? ?? 'Bao Bao',
            plateNumber: acceptedOffer['plate_number'] as String? ?? 'Unknown',
          );

          _clearSessionState(notify: false);
          _driverFoundController.add(result);
        },
      );
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
