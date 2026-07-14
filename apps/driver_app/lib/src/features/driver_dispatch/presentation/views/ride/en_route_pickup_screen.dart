import 'dart:async';
import 'dart:convert';

import 'package:driver_app/src/core/config/environment_config.dart';
import 'package:driver_app/src/core/di/service_locator.dart';
import 'package:driver_app/src/core/services/passenger_api_service.dart';
import 'package:driver_app/src/core/services/telemetry_api_service.dart';
import 'package:driver_app/src/core/services/trip_api_service.dart';
import 'package:driver_app/src/core/themes/app_themes.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/ride/ride_flow_cubit.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/ride/ride_flow_state.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:http/http.dart' as http;
import 'package:location_service/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// En Route Pickup Screen component defining application state or layout.
class EnRoutePickupScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final String duration;

  const EnRoutePickupScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<EnRoutePickupScreen> createState() => _EnRoutePickupScreenState();
}

class _EnRoutePickupScreenState extends State<EnRoutePickupScreen> {
  double _sliderVal = 0;
  bool _isLoading = true;
  double _passengerLat = 0.0;
  double _passengerLng = 0.0;
  Timer? _trackingTimer;

  int _unreadChatMessagesCount = 0;
  int _viewedPassengerMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _startTrackingPassenger(BuildContext context) {
    final cubit = BlocProvider.of<RideFlowCubit>(context);
    final mapBloc = BlocProvider.of<LiveMapBloc>(context);
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      await _updateUnreadMessagesCount(cubit);
      final rideId = cubit.activeRideId;
      if (rideId == null || rideId.isEmpty) return;

      try {
        final loc = await getIt<TelemetryApiService>().fetchPassengerLocation(
          rideId,
        );
        if (loc != null && loc['lat'] != null && loc['lng'] != null) {
          final pLat = (loc['lat'] as num).toDouble();
          final pLng = (loc['lng'] as num).toDouble();
          if (mounted) {
            setState(() {
              _passengerLat = pLat;
              _passengerLng = pLng;
            });
          }
        }
      } catch (_) {}

      try {
        final pos =
            await LocationService.getCurrentPosition() ??
            LocationService.lastPosition;
        if (pos != null) {
          if (mounted) {
            mapBloc.add(
              DispatchTelemetryLocationEvent(
                lat: pos.latitude,
                lng: pos.longitude,
              ),
            );
          }
          if (mounted) {
            mapBloc.add(
              UpdateLocationsAndDrawRouteEvent(
                driverLat: pos.latitude,
                driverLng: pos.longitude,
                passengerLat: _passengerLat,
                passengerLng: _passengerLng,
              ),
            );
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _updateUnreadMessagesCount(RideFlowCubit cubit) async {
    try {
      final rideId = cubit.activeRideId;
      if (rideId == null || rideId.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final driverIdentifier = prefs.getString('driver_id') ?? '';
      if (driverIdentifier.isEmpty) return;

      final gatewayUrl = EnvironmentConfig.httpBaseUrl;
      final chatMessagesEndpointUri = Uri.parse(
        '$gatewayUrl/chat/rooms/$rideId/messages',
      );

      final chatMessagesHttpResponse = await http.get(chatMessagesEndpointUri);
      if (chatMessagesHttpResponse.statusCode == 200) {
        final List<dynamic> chatMessagesList = jsonDecode(
          chatMessagesHttpResponse.body,
        );
        final passengerChatMessagesList = chatMessagesList
            .where(
              (m) =>
                  m is Map<String, dynamic> &&
                  m['senderId'] != driverIdentifier,
            )
            .toList();
        final currentPassengerMessagesCount = passengerChatMessagesList.length;

        if (mounted) {
          setState(() {
            if (!_isInitialChatMessagesCountFetched) {
              _viewedPassengerMessagesCount = currentPassengerMessagesCount;
              _isInitialChatMessagesCountFetched = true;
            } else if (currentPassengerMessagesCount >
                _viewedPassengerMessagesCount) {
              _unreadChatMessagesCount =
                  currentPassengerMessagesCount - _viewedPassengerMessagesCount;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRoute() async {
    final pos =
        await LocationService.getCurrentPosition() ??
        LocationService.lastPosition;
    if (!mounted) return;
    if (pos == null) return;

    final rideState = BlocProvider.of<RideFlowCubit>(context).state;
    if (rideState is RideFlowEnRoutePickup) {
      _passengerLat = rideState.pickupLat;
      _passengerLng = rideState.pickupLng;
    } else {
      final places = await MapProvider.searchPlaces(widget.pickup);
      if (places.isNotEmpty) {
        _passengerLat = places.first.latitude;
        _passengerLng = places.first.longitude;
      } else {
        _passengerLat = pos.latitude;
        _passengerLng = pos.longitude;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    _startTrackingPassenger(context);
  }

  void _triggerDrawRoute(BuildContext context, double dLat, double dLng) {
    BlocProvider.of<LiveMapBloc>(context).add(
      UpdateLocationsAndDrawRouteEvent(
        driverLat: dLat,
        driverLng: dLng,
        passengerLat: _passengerLat,
        passengerLng: _passengerLng,
      ),
    );
  }

  void _onMapCreated(AppMapController controller, BuildContext context) {
    final pos = LocationService.lastPosition;
    final defaultLat = pos?.latitude ?? _passengerLat;
    final defaultLng = pos?.longitude ?? _passengerLng;

    BlocProvider.of<LiveMapBloc>(context).add(
      InitializeMapEvent(
        controller: controller,
        defaultLat: defaultLat,
        defaultLng: defaultLng,
      ),
    );

    if (!_isLoading) {
      _triggerDrawRoute(context, defaultLat, defaultLng);
    }
  }

  void _confirmArrival(BuildContext context) {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowEnRoutePickup
        ? state.passengerName
        : 'Passenger';
    BlocProvider.of<RideFlowCubit>(context).arriveAtPickup(passengerName);
    context.pushReplacementNamed(
      'WaitingPassenger',
      extra: {
        'pickup': widget.pickup,
        'dropoff': widget.dropoff,
        'distance': widget.distance,
        'fare': widget.fare,
        'duration': widget.duration,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveMapBloc>(
      create: (_) => getIt<LiveMapBloc>(),
      child: Builder(
        builder: (context) {
          final rideCubitState = BlocProvider.of<RideFlowCubit>(context).state;
          final defaultLat =
              LocationService.lastPosition?.latitude ??
              (rideCubitState is RideFlowEnRoutePickup
                  ? rideCubitState.pickupLat
                  : 0.0);
          final defaultLng =
              LocationService.lastPosition?.longitude ??
              (rideCubitState is RideFlowEnRoutePickup
                  ? rideCubitState.pickupLng
                  : 0.0);

          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: Stack(
              children: [
                Positioned.fill(
                  child: SizedBox.expand(
                    child: MapProvider.buildMapView(
                      latitude: defaultLat,
                      longitude: defaultLng,
                      zoom: 15.0,
                      onMapCreated: (c) => _onMapCreated(c, context),
                    ),
                  ),
                ),
                SafeArea(child: _buildHeader(context)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(top: 20, bottom: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRouteCard(),
                        const SizedBox(height: 16),
                        _buildInfoRow(),
                        const SizedBox(height: 16),
                        _buildPassengerCard(context),
                        const SizedBox(height: 16),
                        _buildActionRow(context),
                        const SizedBox(height: 20),
                        _buildSlider(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppTheme.neutralColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSide),
              ),
              child: const Icon(
                LucideIcons.arrow_left,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.complete.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.navigation,
                  size: 13,
                  color: AppTheme.complete,
                ),
                const SizedBox(width: 6),
                Text(
                  'EN ROUTE TO PICKUP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.complete,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          children: [
            _routeRow(
              LucideIcons.circle_dot,
              'Pickup',
              widget.pickup,
              AppTheme.primaryColor,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
              child: Row(
                children: [
                  Container(width: 1, height: 16, color: AppTheme.borderSide),
                ],
              ),
            ),
            _routeRow(
              LucideIcons.map_pin,
              'Drop-off',
              widget.dropoff,
              AppTheme.tertiaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _infoChip(LucideIcons.map_pin, '${widget.distance} km'),
          const SizedBox(width: 8),
          _infoChip(LucideIcons.clock, widget.duration),
          const SizedBox(width: 8),
          _infoChip(LucideIcons.banknote, '₱${widget.fare.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppTheme.tertiaryColor),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard(BuildContext context) {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowEnRoutePickup
        ? state.passengerName
        : 'Passenger';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.user,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passengerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Text(
                    'Passenger  •  ★ 4.7',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.tertiaryColor,
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

  Widget _buildActionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _actionBtn(
              LucideIcons.phone,
              'Call',
              AppTheme.primaryColor,
              Colors.white,
              onTap: () async {
                try {
                  final rideCubit = BlocProvider.of<RideFlowCubit>(context);
                  final rideId = rideCubit.activeRideId ?? '';
                  if (rideId.isNotEmpty) {
                    final ride = await getIt<TripApiService>().getRideStatus(
                      rideId,
                    );
                    final passengerId = ride?['passenger_id'] as String?;
                    if (passengerId != null && passengerId.isNotEmpty) {
                      final passenger = await getIt<PassengerApiService>()
                          .fetchPassengerProfile(passengerId);
                      final phone = passenger?['phone'] as String?;
                      if (phone != null && phone.isNotEmpty) {
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    }
                  }
                } catch (_) {}
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionBtn(
              LucideIcons.message_circle,
              'Chat',
              AppTheme.neutralColor,
              AppTheme.primaryColor,
              displayNotificationBadge: _unreadChatMessagesCount > 0,
              notificationBadgeCount: _unreadChatMessagesCount,
              onTap: () async {
                final rideId =
                    BlocProvider.of<RideFlowCubit>(context).activeRideId ?? '';
                final state = BlocProvider.of<RideFlowCubit>(context).state;
                final passengerName = state is RideFlowEnRoutePickup
                    ? state.passengerName
                    : 'Passenger';
                final prefs = await SharedPreferences.getInstance();
                final driverId = prefs.getString('driver_id') ?? '';
                if (!context.mounted) return;
                setState(() {
                  _unreadChatMessagesCount = 0;
                });
                await context.pushNamed(
                  'DriverChat',
                  extra: {
                    'roomId': rideId,
                    'userId': driverId,
                    'peerName': passengerName,
                  },
                );
                if (!context.mounted) return;
                _isInitialChatMessagesCountFetched = false;
                await _updateUnreadMessagesCount(
                  BlocProvider.of<RideFlowCubit>(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color bg,
    Color fg, {
    required VoidCallback onTap,
    bool displayNotificationBadge = false,
    int notificationBadgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(23),
          border: bg == AppTheme.neutralColor
              ? Border.all(color: AppTheme.borderSide)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              label: Text('$notificationBadgeCount'),
              isLabelVisible:
                  displayNotificationBadge && notificationBadgeCount > 0,
              backgroundColor: const Color(0xFFE53935),
              child: Icon(icon, color: fg, size: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final maxW = constraints.maxWidth;
          return Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.complete.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    _sliderVal > 0.8
                        ? 'Release to confirm'
                        : 'Slide to confirm arrival',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.complete.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Positioned(
                  left: _sliderVal * (maxW - 64),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => setState(
                      () => _sliderVal = (_sliderVal + d.delta.dx / (maxW - 64))
                          .clamp(0.0, 1.0),
                    ),
                    onHorizontalDragEnd: (_) {
                      if (_sliderVal > 0.85) {
                        _confirmArrival(context);
                      } else {
                        setState(() => _sliderVal = 0);
                      }
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.complete,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.complete.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.chevron_right,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
