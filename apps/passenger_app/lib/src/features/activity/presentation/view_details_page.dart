import 'package:passenger_app/src/features/active_ride/active_ride.dart';
import 'package:passenger_app/src/features/activity/activity.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/chat/chat_routes.dart';
import 'package:passenger_app/src/features/active_ride/domain/repositories/i_track_repository.dart';
import 'package:shared_core/shared_core.dart';
import 'package:design_system/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityViewDetailsPage extends StatefulWidget {
  final RideHistory? ride;
  final ITrackRepository trackRepository;
  final SecureSessionService sessionService;

  const ActivityViewDetailsPage({
    super.key,
    required this.trackRepository,
    required this.sessionService,
    this.ride,
  });

  @override
  State<ActivityViewDetailsPage> createState() =>
      _ActivityViewDetailsPageState();
}

class _ActivityViewDetailsPageState extends State<ActivityViewDetailsPage> {
  RideSnapshot? _detailedRideData;
  RideCounterparty? _counterpartyData;
  bool _showLostFoundChat = false;
  String _passengerId = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadDetailedRideInfo());
  }

  Future<void> _loadDetailedRideInfo() async {
    final ride = widget.ride;
    if (ride == null) return;

    final passengerId = await widget.sessionService.readPassengerId() ?? '';

    final rideFuture = widget.trackRepository.fetchRide(ride.id);
    final counterpartyFuture = widget.trackRepository.fetchCounterparty(
      ride.id,
    );
    RideSnapshot? retrievedRideData;
    RideCounterparty? counterparty;
    (await rideFuture).fold((_) {}, (value) => retrievedRideData = value);
    (await counterpartyFuture).fold((_) {}, (value) => counterparty = value);

    if (mounted) {
      setState(() {
        _passengerId = passengerId;
        _detailedRideData = retrievedRideData;
        _counterpartyData = counterparty;
        _showLostFoundChat =
            counterparty?.contactAllowed == true &&
            counterparty?.userId.isNotEmpty == true;
      });
    }
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
      if (driverProfile == null) {
        (await widget.trackRepository.fetchCounterparty(
          ride.id,
        )).fold((_) {}, (value) => driverProfile = value);
      }
      final phone = driverProfile?.phone ?? '';
      if (phone.isNotEmpty) {
        final uri = Uri.parse('tel:$phone');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (_) {}
  }

  Future<void> _onMapCreated(AppMapController controller) async {
    final ride = widget.ride;
    if (ride == null) return;
    final routeColor = context.colorScheme.onSurface;

    try {
      await MapProvider.addMarker(
        controller,
        ride.pickupLat,
        ride.pickupLng,
        isOrigin: true,
      );
      await MapProvider.addMarker(
        controller,
        ride.destLat,
        ride.destLng,
        isOrigin: false,
      );

      final route = await MapProvider.getRoute(
        ride.pickupLat,
        ride.pickupLng,
        ride.destLat,
        ride.destLng,
      );
      if (route != null) {
        await MapProvider.addPolyline(
          controller,
          route.polylinePoints,
          color: routeColor,
          width: 4.0,
        );
      }

      await MapProvider.fitBounds(controller, [
        LatLng(ride.pickupLat, ride.pickupLng),
        LatLng(ride.destLat, ride.destLng),
      ], padding: 40.0);
    } catch (error) {
      debugPrint('ActivityViewDetailsPage._onMapCreated failed: $error');
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

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: IconButton(
            onPressed: () => context.pop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            icon: Icon(
              LucideIcons.arrow_left,
              color: context.colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Ride details',
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                  width: 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: MapProvider.buildMapView(
                        latitude: centerLat,
                        longitude: centerLng,
                        zoom: 13.0,
                        interactive: false,
                        onMapCreated: _onMapCreated,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: context.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Map preview',
                          style: TextStyle(
                            color: context.colorScheme.surface,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.user,
                      color: context.semanticColors.warmAccent,
                      size: 22,
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
                  GestureDetector(
                    onTap: _makeDriverCall,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          width: 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.phone,
                        color: context.colorScheme.onSurface,
                        size: 16,
                      ),
                    ),
                  ),
                  if (status != 'completed' || _showLostFoundChat) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _initiateLostFoundChat,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.message_square,
                          color: context.colorScheme.onSurface,
                          size: 16,
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
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
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        statusSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
                borderRadius: BorderRadius.circular(20),
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
