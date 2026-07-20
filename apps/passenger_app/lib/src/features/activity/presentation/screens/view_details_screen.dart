import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/features/chat/chat_routes.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityViewDetailsScreen extends StatefulWidget {
  final RideHistoryModel? ride;

  const ActivityViewDetailsScreen({super.key, this.ride});

  @override
  State<ActivityViewDetailsScreen> createState() => _ActivityViewDetailsScreenState();
}

class _ActivityViewDetailsScreenState extends State<ActivityViewDetailsScreen> {
  Map<String, dynamic>? _detailedRideData;
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

    final sharedPreferencesInstance = await SharedPreferences.getInstance();
    final passengerId =
        sharedPreferencesInstance.getString('passenger_id') ?? '';

    final retrievedRideData = await Modular.get<BiddingRemoteDataSource>().getRideStatus(
      ride.id,
    );
    bool isWithinGracePeriodWindow = false;
    try {
      final rideCompletedTime = DateTime.parse(ride.date).toLocal();
      final elapsedTimeSinceCompletion = DateTime.now().difference(
        rideCompletedTime,
      );
      if (elapsedTimeSinceCompletion.inHours < 48) {
        isWithinGracePeriodWindow = true;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _passengerId = passengerId;
        _detailedRideData = retrievedRideData;
        _showLostFoundChat =
            isWithinGracePeriodWindow &&
            retrievedRideData != null &&
            retrievedRideData['driver_id'] != null;
      });
    }
  }

  Future<void> _initiateLostFoundChat() async {
    final ride = widget.ride;
    final retrievedRideData = _detailedRideData;
    if (ride == null || retrievedRideData == null || _passengerId.isEmpty) {
      return;
    }

    final driverId = retrievedRideData['driver_id'] as String?;
    if (driverId == null || driverId.isEmpty) return;

    try {
      final initializeRoomResponse = await Dio().postUri(
        EnvironmentConfig.httpBaseUri.replace(path: '/chat/rooms'),
        data: {
          'roomId': ride.id,
          'driverId': driverId,
          'passengerId': _passengerId,
        },
      );

      if (initializeRoomResponse.statusCode == 201 ||
          initializeRoomResponse.statusCode == 200) {
        if (mounted) {
          unawaited(
            context.pushNamed(
              ChatRoutes.driverChat,
              extra: {
                'roomId': ride.id,
                'userId': _passengerId,
                'peerName': retrievedRideData['driver_name'] ?? 'Driver',
              },
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _makeDriverCall() async {
    final retrievedRideData = _detailedRideData;
    if (retrievedRideData == null) return;
    final driverId = retrievedRideData['driver_id'] as String?;
    if (driverId == null || driverId.isEmpty) return;
    try {
      final driverProfile = await Modular.get<BiddingRemoteDataSource>().getDriverProfile(driverId);
      final phone = driverProfile?['phone'] as String?;
      if (phone != null && phone.isNotEmpty) {
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
          color: AppTheme.primaryColor,
          width: 4.0,
        );
      }

      await MapProvider.fitBounds(controller, [
        LatLng(ride.pickupLat, ride.pickupLng),
        LatLng(ride.destLat, ride.destLng),
      ], padding: 40.0);
    } catch (error) {
      debugPrint('ActivityViewDetailsScreen._onMapCreated failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;

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
      statusColor = AppTheme.complete;
      statusLabel = 'COMPLETED';
      statusSubtitle = 'Trip finished';
    } else if (status == 'canceled' || status == 'cancelled') {
      statusColor = AppTheme.cancel;
      statusLabel = 'CANCELED';
      statusSubtitle = 'Trip canceled';
    } else {
      statusColor = const Color(0xFFD25D38);
      statusLabel = 'ON THE WAY';
      statusSubtitle = 'Arriving in 6 min';
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ride details',
          style: TextStyle(
            color: AppTheme.primaryColor,
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
                color: AppTheme.neutralColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.borderSide.withValues(alpha: 0.2),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Map preview',
                          style: TextStyle(
                            color: Colors.white,
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
                color: AppTheme.neutralColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.borderSide.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.user,
                      color: Color(0xFF8A4F35),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride?.driverName.isNotEmpty == true
                              ? ride!.driverName
                              : 'Driver',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ride?.vehicleType ?? 'Bao Bao'}  •  ${ride?.vehiclePlate ?? '—'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
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
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.borderSide.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.phone,
                        color: AppTheme.primaryColor,
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
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.borderSide.withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.message_square,
                          color: AppTheme.primaryColor,
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
                color: AppTheme.neutralColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.borderSide.withValues(alpha: 0.2),
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
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        statusSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, color: AppTheme.borderSide),
                  ),
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.tertiaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: AppTheme.outlineBorderColor,
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride?.pickup ?? 'Pickup Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              ride?.destination ?? 'Destination Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.neutralColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.borderSide.withValues(alpha: 0.2),
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
                        ride?.vehicleType.toLowerCase().contains('share') == true
                            ? 'Fare, shared ride'
                            : 'Fare, solo ride',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.banknote,
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pay with cash',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    ride?.price ?? '—',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
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
