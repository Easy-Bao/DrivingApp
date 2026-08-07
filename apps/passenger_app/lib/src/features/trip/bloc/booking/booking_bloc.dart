import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/services/background_telemetry_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/domain/entities/bid_session_trip.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:shared_core/shared_core.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final IDriverRepository _driverRepository;
  final BiddingRemoteDataSource _biddingDataSource;
  final SecureSessionService _secureSessionService;
  final BackgroundTelemetryService? _backgroundTelemetryService;
  final InboxCubit? _inboxCubit;

  StreamSubscription<List<dynamic>>? _offersSubscription;
  StreamSubscription<DriverMatchResult>? _driverFoundSubscription;

  DriverModel? _nearestDriver;
  int? _totalTrips;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = false;
  bool _nearestSearchCancelled = false;
  bool _noDriverNotificationSent = false;
  bool _isAutoAcceptingOffer = false;
  String? _activeBidSessionId;

  double? _pickupLat;
  double? _pickupLng;
  String? _pickupName;
  double? _dropoffLat;
  double? _dropoffLng;
  String? _dropoffName;

  String? _sessionIdFromResponse(Map<String, dynamic> response) {
    final rawSessionId = response['id'];
    final sessionId = switch (rawSessionId) {
      final String value => value.trim(),
      final num value => value.toInt().toString(),
      _ => null,
    };
    return sessionId == null || sessionId.isEmpty ? null : sessionId;
  }

  Future<String> _resolvePickupName() async {
    final providedName = _pickupName?.trim();
    if (providedName != null &&
        providedName.isNotEmpty &&
        providedName != 'Current Location') {
      return providedName;
    }

    final lat = _pickupLat;
    final lng = _pickupLng;
    if (lat == null || lng == null) return providedName ?? 'Current Location';

    try {
      final place = await MapProvider.getPlaceFromCoordinates(lat, lng);
      final resolvedName = place?.fullAddress.trim();
      return resolvedName == null || resolvedName.isEmpty
          ? providedName ?? 'Current Location'
          : resolvedName;
    } catch (_) {
      return providedName ?? 'Current Location';
    }
  }

  BookingBloc({
    required IDriverRepository driverRepository,
    required BiddingRemoteDataSource biddingDataSource,
    required SecureSessionService secureSessionService,
    InboxCubit? inboxCubit,
    BackgroundTelemetryService? backgroundTelemetryService,
  }) : _driverRepository = driverRepository,
       _biddingDataSource = biddingDataSource,
       _secureSessionService = secureSessionService,
       _inboxCubit = inboxCubit,
       _backgroundTelemetryService = backgroundTelemetryService,
       super(BookingInitial()) {
    on<LocateNearestDriverEvent>(_onLocateNearestDriver);
    on<StartDirectBookingEvent>(_onStartDirectBooking);
    on<StartOpenBookingEvent>(_onStartOpenBooking);
    on<AcceptBidOfferEvent>(_onAcceptBidOffer);
    on<CancelBookingEvent>(_onCancelBooking);
    on<UpdateOffersEvent>(_onUpdateOffers);
    on<DriverMatchedEvent>(_onDriverMatched);
  }

  bool get hasActiveDriverSearch =>
      state is FindingNearestDriver ||
      state is NearestDriverFound ||
      state is BookingSearching ||
      state is BookingOffersReceived;

  bool get hasActiveBooking =>
      state is BookingSearching ||
      state is BookingOffersReceived ||
      state is BookingDriverMatched;

  Future<void> _onLocateNearestDriver(
    LocateNearestDriverEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveDriverSearch) return;
    _nearestSearchCancelled = false;
    _noDriverNotificationSent = false;
    _isAutoAcceptingOffer = false;
    emit(
      FindingNearestDriver(
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
      ),
    );

    List<DriverModel> nearbyDrivers = [];
    Failure? lastFailure;

    for (int attempt = 0; attempt < 5; attempt++) {
      final result = await _driverRepository.getNearbyDrivers(
        lat: event.pickupLat,
        lng: event.pickupLng,
      );
      if (isClosed || _nearestSearchCancelled) return;

      result.fold(
        (failure) {
          lastFailure = failure;
        },
        (drivers) {
          nearbyDrivers = drivers;
        },
      );

      if (nearbyDrivers.isNotEmpty) break;
      await Future.delayed(const Duration(seconds: 2));
      if (isClosed || _nearestSearchCancelled) return;
    }

    if (nearbyDrivers.isEmpty) {
      if (!_nearestSearchCancelled) {
        _notifyNoDriverFound();
      }
      if (isClosed || _nearestSearchCancelled) return;
      emit(
        BookingFailure(
          lastFailure?.message ?? 'No drivers nearby. Please try again.',
          isNoDriverFound: true,
        ),
      );
      return;
    }

    DriverModel closestDriver = nearbyDrivers.first;
    for (final d in nearbyDrivers) {
      if (d.distanceKm < closestDriver.distanceKm) {
        closestDriver = d;
      }
    }
    _nearestDriver = closestDriver;

    try {
      final stats = await _biddingDataSource.fetchDriverStats(closestDriver.id);
      final totalTrips = stats['totalTrips'] ?? stats['total_trips'];
      _totalTrips = (totalTrips as num?)?.toInt();
    } catch (error) {
      dev.log('Unable to load driver stats: $error');
      _totalTrips = null;
    }

    try {
      _isLoadingReviews = true;
      emit(
        NearestDriverFound(
          driver: closestDriver,
          nearbyDrivers: nearbyDrivers,
          totalTrips: _totalTrips,
          reviews: const [],
          isLoadingReviews: true,
          trip: event.trip,
          pickupLat: event.pickupLat,
          pickupLng: event.pickupLng,
        ),
      );

      final rawReviews = await _biddingDataSource.fetchDriverReviews(
        closestDriver.id,
      );
      final List<Map<String, dynamic>> processedReviews = [];
      for (final r in rawReviews) {
        if (r is Map<String, dynamic>) {
          final createdAtStr = r['createdAt'] ?? r['created_at'];
          var dateFormatted = '';
          if (createdAtStr != null) {
            try {
              final parsedDate = DateTime.parse(createdAtStr.toString());
              final months = [
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
              dateFormatted =
                  '${months[parsedDate.month - 1]} ${parsedDate.day}, ${parsedDate.year}';
            } catch (error) {
              dev.log('Failed to parse review date: $error');
            }
          }
          processedReviews.add({
            'passengerName': r['passengerName'] ?? r['passenger_name'],
            'comment': r['comment'],
            'rating': (r['rating'] as num?)?.toDouble(),
            'date': dateFormatted,
          });
        }
      }
      _reviews = processedReviews;
    } catch (error) {
      dev.log('Failed to process reviews: $error');
      _reviews = const [];
    } finally {
      _isLoadingReviews = false;
    }

    emit(
      NearestDriverFound(
        driver: closestDriver,
        nearbyDrivers: nearbyDrivers,
        totalTrips: _totalTrips,
        reviews: _reviews,
        isLoadingReviews: _isLoadingReviews,
        trip: event.trip,
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
      ),
    );
  }

  void _notifyNoDriverFound() {
    final inboxCubit = _inboxCubit;
    if (_noDriverNotificationSent ||
        inboxCubit == null ||
        inboxCubit.isClosed) {
      return;
    }
    _noDriverNotificationSent = true;
    inboxCubit.addLocalNotification(
      InboxNotification(
        id: 'no-driver-${DateTime.now().millisecondsSinceEpoch}',
        title: 'No driver found',
        message:
            'We could not find a driver for your ride. You can try searching again.',
        timestamp: DateTime.now(),
        type: 'driver',
        isRead: false,
      ),
    );
  }

  Future<void> _onStartDirectBooking(
    StartDirectBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    final nearestDriver = _nearestDriver;
    if (nearestDriver == null || hasActiveBooking) return;
    final targetDriverId = int.tryParse(nearestDriver.id);
    if (targetDriverId == null || targetDriverId <= 0) {
      emit(const BookingFailure('The selected driver ID is invalid.'));
      return;
    }
    _isAutoAcceptingOffer = false;
    emit(BookingSearching(isDirect: true, targetDriver: nearestDriver));

    final passengerId = await _secureSessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      emit(const BookingFailure('Passenger ID is missing.'));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = event.trip.pickupAddress ?? 'Current Location';
    _pickupName = await _resolvePickupName();
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;

    try {
      final response = await _biddingDataSource.requestRide({
        'ride_type': event.trip.rideType,
        'pickup_latitude': event.pickupLat,
        'pickup_longitude': event.pickupLng,
        'pickup_name': _pickupName,
        'dropoff_latitude': _dropoffLat,
        'dropoff_longitude': _dropoffLng,
        'dropoff_name': _dropoffName,
        'distance_km': event.distanceKm,
        'duration_minutes': event.durationMinutes,
        'target_driver_id': targetDriverId,
        'custom_fare_centavos': (event.trip.fare * 100).round(),
      });
      final sessionId = _sessionIdFromResponse(response);
      if (sessionId == null || sessionId.isEmpty) {
        throw StateError('Booking session was not created');
      }
      _activeBidSessionId = sessionId;
      _subscribeToSession(sessionId);
    } catch (error) {
      emit(BookingFailure(ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> _onStartOpenBooking(
    StartOpenBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (hasActiveBooking) return;
    emit(const BookingSearching(isDirect: false));

    final passengerId = await _secureSessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      emit(const BookingFailure('Passenger ID is missing.'));
      return;
    }

    _pickupLat = event.pickupLat;
    _pickupLng = event.pickupLng;
    _pickupName = event.trip.pickupAddress ?? 'Current Location';
    _pickupName = await _resolvePickupName();
    _dropoffLat = event.trip.destination.latitude;
    _dropoffLng = event.trip.destination.longitude;
    _dropoffName = event.trip.destination.name;

    try {
      final response = await _biddingDataSource.requestRide({
        'ride_type': event.trip.rideType,
        'pickup_latitude': event.pickupLat,
        'pickup_longitude': event.pickupLng,
        'pickup_name': _pickupName,
        'dropoff_latitude': _dropoffLat,
        'dropoff_longitude': _dropoffLng,
        'dropoff_name': _dropoffName,
        'distance_km': event.distanceKm,
        'duration_minutes': event.durationMinutes,
        'custom_fare_centavos': (event.trip.fare * 100).round(),
      });
      final sessionId = _sessionIdFromResponse(response);
      if (sessionId == null || sessionId.isEmpty) {
        throw StateError('Booking session was not created');
      }
      _activeBidSessionId = sessionId;
      _subscribeToSession(sessionId);
    } catch (error) {
      emit(BookingFailure(ErrorHandler.getErrorMessage(error)));
    }
  }

  void _subscribeToSession(String sessionId) {
    unawaited(_offersSubscription?.cancel());
    unawaited(_driverFoundSubscription?.cancel());

    _offersSubscription = Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) async {
          try {
            return await _biddingDataSource.fetchOffers(sessionId);
          } catch (error) {
            dev.log('Failed to poll booking offers: $error');
            return const <dynamic>[];
          }
        })
        .listen((offers) {
          add(UpdateOffersEvent(offers));
        });
  }

  void _onUpdateOffers(UpdateOffersEvent event, Emitter<BookingState> emit) {
    final isDirectBooking = switch (state) {
      BookingSearching(:final isDirect) => isDirect,
      BookingOffersReceived(:final isDirect) => isDirect,
      _ => false,
    };

    if (isDirectBooking && event.offers.isNotEmpty && !_isAutoAcceptingOffer) {
      final pendingOffer = event.offers
          .whereType<Map<String, dynamic>>()
          .where((offer) => offer['status'] == 'pending')
          .firstWhere((_) => true, orElse: () => <String, dynamic>{});
      final offerId = pendingOffer['id']?.toString() ?? '';
      final proposedFareCentavos =
          (pendingOffer['proposed_fare_centavos'] as num?)?.toInt();
      final driverId = pendingOffer['driver_id']?.toString() ?? '';
      if (offerId.isNotEmpty &&
          driverId.isNotEmpty &&
          proposedFareCentavos != null &&
          proposedFareCentavos > 0) {
        _isAutoAcceptingOffer = true;
        add(
          AcceptBidOfferEvent(
            offerId: offerId,
            driverId: driverId,
            driverName: pendingOffer['driver_name']?.toString() ?? '',
            vehicleType: pendingOffer['vehicle_type']?.toString() ?? '',
            plateNumber: pendingOffer['plate_number']?.toString() ?? '',
            proposedFare: proposedFareCentavos / 100,
            driverRating: pendingOffer['driver_rating']?.toString(),
          ),
        );
        return;
      }
    }

    if (state is BookingSearching) {
      final current = state as BookingSearching;
      emit(
        BookingOffersReceived(
          offers: event.offers,
          isDirect: current.isDirect,
          targetDriver: current.targetDriver,
        ),
      );
    } else if (state is BookingOffersReceived) {
      final current = state as BookingOffersReceived;
      emit(
        BookingOffersReceived(
          offers: event.offers,
          isDirect: current.isDirect,
          targetDriver: current.targetDriver,
        ),
      );
    }
  }

  Future<void> _onDriverMatched(
    DriverMatchedEvent event,
    Emitter<BookingState> emit,
  ) async {
    _nearestSearchCancelled = true;
    _cleanupSubscriptions();

    emit(BookingDriverMatched(matchResult: event.matchResult));
  }

  Future<void> _onAcceptBidOffer(
    AcceptBidOfferEvent event,
    Emitter<BookingState> emit,
  ) async {
    final sessionId = _activeBidSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      emit(const BookingFailure('Booking session is no longer available.'));
      return;
    }

    try {
      final response = await _biddingDataSource.acceptOffer(
        sessionId: sessionId,
        offerId: event.offerId,
      );
      final ride = response['ride'];
      final rideMap = ride is Map<String, dynamic>
          ? ride
          : const <String, dynamic>{};
      final rideId =
          response['ride_id']?.toString() ?? rideMap['id']?.toString() ?? '';
      if (rideId.isEmpty) {
        throw StateError('Accepted booking did not return a ride ID');
      }

      final pickupLat = _pickupLat;
      final pickupLng = _pickupLng;
      final dropoffLat = _dropoffLat;
      final dropoffLng = _dropoffLng;
      if (pickupLat == null ||
          pickupLng == null ||
          dropoffLat == null ||
          dropoffLng == null) {
        throw StateError('Booking coordinates are unavailable');
      }
      final fareCentavos =
          (rideMap['fare_centavos'] as num?)?.toDouble() ??
          event.proposedFare * 100;
      await _secureSessionService.saveActiveRideId(rideId);
      await _startBackgroundTelemetry();
      _cleanupSubscriptions();
      emit(
        BookingDriverMatched(
          matchResult: DriverMatchResult(
            driverId: event.driverId,
            driverName: event.driverName,
            vehicleType: event.vehicleType,
            plateNumber: event.plateNumber,
            proposedFare: event.proposedFare,
            driverRating: event.driverRating,
          ),
          createdRide: RideHistoryModel(
            id: rideId,
            pickup: _pickupName ?? '',
            destination: _dropoffName ?? '',
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            destLat: dropoffLat,
            destLng: dropoffLng,
            date: DateTime.now().toLocal().toString(),
            price: '₱${(fareCentavos / 100).toStringAsFixed(2)}',
            status: RideStatus.accepted.value,
            driverId: event.driverId,
            driverName: event.driverName,
            vehiclePlate: event.plateNumber,
            vehicleType: event.vehicleType,
          ),
        ),
      );
    } catch (error) {
      _isAutoAcceptingOffer = false;
      emit(BookingFailure(ErrorHandler.getErrorMessage(error)));
    }
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    _nearestSearchCancelled = true;
    _cleanupSubscriptions();
    await _stopBackgroundTelemetry();
    final sessionId = _activeBidSessionId;
    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        await _biddingDataSource
            .cancelSession(sessionId)
            .timeout(const Duration(seconds: 5));
      }
    } catch (error) {
      dev.log('Unable to confirm booking cancellation: $error');
    }
    emit(BookingCanceled());
    _activeBidSessionId = null;
  }

  void _cleanupSubscriptions() {
    unawaited(_offersSubscription?.cancel());
    unawaited(_driverFoundSubscription?.cancel());
    _offersSubscription = null;
    _driverFoundSubscription = null;
  }

  Future<void> _startBackgroundTelemetry() async {
    final service = _backgroundTelemetryService;
    if (service == null) return;
    try {
      await service.start();
    } catch (error) {
      dev.log('Unable to start passenger background telemetry: $error');
    }
  }

  Future<void> _stopBackgroundTelemetry() async {
    final service = _backgroundTelemetryService;
    if (service == null) return;
    try {
      await service.stop();
    } catch (error) {
      dev.log('Unable to stop passenger background telemetry: $error');
    }
  }

  @override
  Future<void> close() {
    _cleanupSubscriptions();
    unawaited(_stopBackgroundTelemetry());
    return super.close();
  }
}
