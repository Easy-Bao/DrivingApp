import 'dart:async';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:url_launcher/url_launcher.dart';

class const RideDetailsPage({
  super.key,
  required this.trackRepository,
  required this.sessionService,
  this.detailsCubit,
  this.ride,
}) extends StatefulWidget {
  final RideHistory? ride;
  final TrackRepository trackRepository;
  final PassengerSessionStore sessionService;
  final RideDetailsCubit? detailsCubit;

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  late final RideDetailsCubit _detailsCubit;
  StreamSubscription<RideDetailsState>? _detailsSubscription;
  RideSnapshot? _detailedRideData;
  RideCounterparty? _counterpartyData;
  bool _showLostFoundChat = false;
  String _passengerId = '';
  Future<Route?>? _routeFuture;

  @override
  void initState() {
    super.initState();
    final ride = widget.ride;
    if (ride != null) {
      _routeFuture = MapProvider.getRoute(
        ride.pickupLat,
        ride.pickupLng,
        ride.destLat,
        ride.destLng,
      );
    }
    _detailsCubit =
        widget.detailsCubit ??
        RideDetailsCubit(
          repository: widget.trackRepository,
          sessionService: widget.sessionService,
        );
    _syncDetailsState(_detailsCubit.state);
    _detailsSubscription = _detailsCubit.stream.listen((state) {
      if (!mounted) return;
      setState(() => _syncDetailsState(state));
    });
    final rideId = widget.ride?.id;
    if (rideId != null) unawaited(_detailsCubit.load(rideId));
  }

  void _syncDetailsState(RideDetailsState state) {
    _passengerId = state.passengerId;
    _detailedRideData = state.ride;
    _counterpartyData = state.counterparty;
    _showLostFoundChat = state.canContactCounterparty;
  }

  @override
  void dispose() {
    unawaited(_detailsSubscription?.cancel());
    unawaited(_detailsCubit.close());
    super.dispose();
  }

  Future<void> _initiateLostFoundChat() async {
    final ride = widget.ride;
    final retrievedRideData = _detailedRideData;
    if (ride == null || retrievedRideData == null || _passengerId.isEmpty) {
      return;
    }

    final driverId =
        _counterpartyData?.userId ?? retrievedRideData.driverId ?? '';
    if (driverId.isEmpty) return;

    try {
      if (mounted) {
        unawaited(
          context.pushNamed(
            ChatRoutes.driverChat,
            extra: {
              'roomId': ride.id,
              'userId': _passengerId,
              'peerId': driverId,
              'peerName': SafeParse.toStringValue(
                _counterpartyData?.name ?? retrievedRideData.driverName,
                'Driver',
              ),
            },
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _makeDriverCall() async {
    final ride = widget.ride;
    if (ride == null) return;
    try {
      RideCounterparty? driverProfile = _counterpartyData;
      driverProfile ??= await _detailsCubit.loadCounterpartyIfNeeded(ride.id);
      final phone = driverProfile?.phone ?? '';
      if (phone.isNotEmpty) {
        final uri = Uri.parse('tel:$phone');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (_) {}
  }

  String _driverInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'D';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _onMapCreated(AppMapController controller) async {
    final ride = widget.ride;
    if (ride == null) return;
    final routeColor = context.colorScheme.primary;

    try {
      unawaited(
        MapProvider.fitBounds(
          controller,
          [
            LatLng(ride.pickupLat, ride.pickupLng),
            LatLng(ride.destLat, ride.destLng),
          ],
          padding: 44.0,
        ),
      );

      unawaited(
        Future.wait([
          MapProvider.addMarker(
            controller,
            ride.pickupLat,
            ride.pickupLng,
            isOrigin: true,
          ),
          MapProvider.addMarker(
            controller,
            ride.destLat,
            ride.destLng,
            isOrigin: false,
          ),
        ]),
      );

      final initialBuffer = Float64List.fromList([
        ride.pickupLat,
        ride.pickupLng,
        ride.destLat,
        ride.destLng,
      ]);
      await MapProvider.addPolylineBuffer(
        controller,
        initialBuffer,
        color: routeColor.withValues(alpha: 0.35),
        width: 3.5,
      );

      final route = await (_routeFuture ??
          MapProvider.getRoute(
            ride.pickupLat,
            ride.pickupLng,
            ride.destLat,
            ride.destLng,
          ));

      if (!mounted) return;
      if (route != null && route.hasGeometry) {
        await MapProvider.addPolylineBuffer(
          controller,
          route.coordinateBuffer,
          color: routeColor,
          width: 4.5,
        );
      }
    } catch (error) {
      debugPrint('RideDetailsPage._onMapCreated failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final fare = ride == null
        ? null
        : double.tryParse(ride.price.replaceAll(RegExp(r'[^0-9.\-]'), ''));

    final centerLat = ride != null
        ? (ride.pickupLat + ride.destLat) / 2
        : 7.8300;
    final centerLng = ride != null
        ? (ride.pickupLng + ride.destLng) / 2
        : 123.4400;

    final status = ride?.status.toLowerCase() ?? 'completed';
    final Color statusColor;
    final String statusLabel;
    final String statusSubtitle;

    if (status == 'completed') {
      statusColor = context.semanticColors.success;
      statusLabel = 'Completed';
      statusSubtitle = 'Trip finished';
    } else if (status == 'canceled' || status == 'cancelled') {
      statusColor = context.colorScheme.error;
      statusLabel = 'Canceled';
      statusSubtitle = 'Trip canceled';
    } else {
      statusColor = context.semanticColors.success;
      statusLabel = 'In Progress';
      statusSubtitle = 'Trip is in progress';
    }

    return EasyRideSecondaryPage(
      title: 'Ride details',
      onBack: () => context.pop(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.25,
                  ),
                  width: 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(EasyRideRadius.lg - 1),
                child: MapProvider.buildMapView(
                  latitude: centerLat,
                  longitude: centerLng,
                  zoom: 13.0,
                  interactive: false,
                  onMapCreated: _onMapCreated,
                ),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.25,
                  ),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _driverInitials(ride?.displayDriverName),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride?.displayDriverName ?? 'Driver',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride?.displayVehicleSummary ??
                              'Vehicle details unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: context.colorScheme.surface,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: context.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                        width: 1.0,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _makeDriverCall,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          LucideIcons.phone,
                          color: context.colorScheme.onSurface,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  if (status != 'completed' || _showLostFoundChat) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: context.colorScheme.surface,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: context.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _initiateLostFoundChat,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            LucideIcons.message_square,
                            color: context.colorScheme.onSurface,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.25,
                  ),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            EasyRideRadius.pill,
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Text(
                        statusSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(
                      height: 1,
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  CompactRouteTimelineWidget(
                    pickup: ride?.pickup ?? 'Pickup Location',
                    dropoff: ride?.destination ?? 'Destination Location',
                    pickupLabel: 'Pickup',
                    dropoffLabel: 'Drop Off',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride?.vehicleType.toLowerCase().contains('share') ==
                                true
                            ? 'Fare, shared ride'
                            : 'Fare, solo ride',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.banknote,
                            color: context.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pay with cash',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    fare == null ? '—' : formatPesoAmount(fare),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
