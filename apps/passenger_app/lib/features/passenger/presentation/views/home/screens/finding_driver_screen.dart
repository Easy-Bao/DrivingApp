import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/core/di/service_locator.dart';
import 'package:passenger_app/core/services/bid_session_service.dart';
import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FindingDriverScreen extends StatefulWidget {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? pickupAddress;

  const FindingDriverScreen({
    super.key,
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.pickupAddress,
  });

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarCtrl;
  late AnimationController _dotCtrl;
  bool _initialized = false;

  List<dynamic> _offers = [];

  StreamSubscription? _offersSubscription;
  StreamSubscription? _driverFoundSubscription;
  late BidSessionService _bidSessionService;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_radarCtrl.repeat());
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    unawaited(_dotCtrl.repeat());

    _bidSessionService = getIt<BidSessionService>();
    unawaited(_initializeBookingSearchFlow());
  }

  Future<void> _initializeBookingSearchFlow() async {
    _bidSessionService.setForeground(true);

    _offersSubscription = _bidSessionService.offersStream.listen((updatedOffersList) {
      if (mounted) {
        setState(() {
          _offers = updatedOffersList;
        });
      }
    });

    _driverFoundSubscription = _bidSessionService.driverFoundStream.listen((driverMatchResult) {
      if (mounted) {
        context.pushReplacementNamed(
          'DriverMatched',
          extra: driverMatchResult.toNavigationExtra(),
        );
      }
    });

    if (_bidSessionService.isActive) {
      setState(() {
        _offers = _bidSessionService.offers;
      });
    } else {
      final sharedPreferencesInstance = await SharedPreferences.getInstance();
      final passengerId = sharedPreferencesInstance.getString('passenger_id') ?? '';
      if (passengerId.isEmpty) return;

      final pickupLat = LocationService.lastPosition?.latitude ?? widget.destination.latitude;
      final pickupLng = LocationService.lastPosition?.longitude ?? widget.destination.longitude;

      final distanceNum =
          double.tryParse(widget.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          1.0;
      final durationNum =
          double.tryParse(widget.duration.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          5.0;

      final tripMetadata = BidSessionTrip(
        rideType: widget.rideType,
        fare: widget.fare,
        destination: widget.destination,
        distance: widget.distance,
        duration: widget.duration,
        pickupAddress: widget.pickupAddress,
      );

      await _bidSessionService.startSession(
        trip: tripMetadata,
        passengerId: passengerId,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        distanceKm: distanceNum,
        durationMinutes: durationNum,
      );
    }
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _dotCtrl.dispose();
    unawaited(_offersSubscription?.cancel());
    unawaited(_driverFoundSubscription?.cancel());
    super.dispose();
  }

  void _onMapCreated(AppMapController controller) {
    if (!_initialized) {
      _initialized = true;
      final lat = LocationService.lastPosition?.latitude ?? widget.destination.latitude;
      final lng = LocationService.lastPosition?.longitude ?? widget.destination.longitude;
      unawaited(MapProvider.addMarker(controller, lat, lng, isOrigin: true));
    }
  }

  void _handleBackground() {
    _bidSessionService.backgroundSearch();
    context.goNamed('PassengerHome');
  }

  Future<void> _handleCancel() async {
    await _bidSessionService.cancelSession();
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultLat = LocationService.lastPosition?.latitude ?? widget.destination.latitude;
    final defaultLng = LocationService.lastPosition?.longitude ?? widget.destination.longitude;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackground();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppTheme.neutralColor,
                child: MapProvider.buildMapView(
                  latitude: defaultLat,
                  longitude: defaultLng,
                  zoom: 14.5,
                  interactive: true,
                  onMapCreated: _onMapCreated,
                ),
              ),
            ),
            if (_offers.isEmpty)
              Center(
                child: AnimatedBuilder(
                  animation: _radarCtrl,
                  builder: (ctx, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (i) {
                          final timerSeconds = (_radarCtrl.value + i * 0.33) % 1.0;
                          return Container(
                            width: 60 + timerSeconds * 200,
                            height: 60 + timerSeconds * 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.15 * (1 - timerSeconds),
                                ),
                                width: 2,
                              ),
                            ),
                          );
                        }),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.navigation,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: _handleBackground,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.arrow_left,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _offers.isEmpty ? _buildSearchingPanel() : _buildBidsPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _dotCtrl,
            builder: (ctx, _) {
              final dots = '.' * (1 + (_dotCtrl.value * 3).floor());
              return Text(
                'Finding your driver$dots',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Looking for ${widget.rideType} drivers nearby...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderSide),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.map_pin,
                      size: 16,
                      color: AppTheme.tertiaryColor,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 160,
                      child: Text(
                        widget.destination.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${widget.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _handleCancel,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cancel.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Text(
                'Cancel Search',
                style: TextStyle(
                  color: AppTheme.cancel,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidsPanel() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Select Driver Offer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Drivers nearby have placed these bids for your trip',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _offers.length,
              itemBuilder: (context, index) {
                final offer = _offers[index] as Map<String, dynamic>;
                final driverName = offer['driver_name'] as String? ?? 'Driver';
                final vehicleType =
                    offer['vehicle_type'] as String? ?? 'Bao Bao';
                final plateNumber =
                    offer['plate_number'] as String? ?? 'Unknown';
                final proposedFare =
                    (offer['proposed_fare'] as num?)?.toDouble() ?? widget.fare;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSide),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      child: const Icon(
                        LucideIcons.user,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '$vehicleType • $plateNumber',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₱${proposedFare.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Accept Bid',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.complete,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await _bidSessionService.acceptOffer(
                        offerId: offer['id'] as String,
                        driverName: driverName,
                        vehicleType: vehicleType,
                        plateNumber: plateNumber,
                        proposedFare: proposedFare,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _handleCancel,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cancel.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Text(
                'Cancel Search',
                style: TextStyle(
                  color: AppTheme.cancel,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
