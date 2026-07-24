import 'dart:async';

import 'package:chat_service/chat_service.dart';
import 'package:driver_app/src/features/chat/chat_routes.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver_app/src/features/trip/presentation/widgets/waiting_passenger_panel_widget.dart';
import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:driver_services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class WaitingPassengerScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;

  const WaitingPassengerScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<WaitingPassengerScreen> createState() => _WaitingPassengerScreenState();
}

class _WaitingPassengerScreenState extends State<WaitingPassengerScreen> {
  int _waitSeconds = 0;
  Timer? _waitTimer;

  int _unreadChatMessagesCount = 0;
  int _viewedPassengerMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;

  @override
  void initState() {
    super.initState();
    final cubit = BlocProvider.of<RideFlowCubit>(context);
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        setState(() => _waitSeconds++);
        if (_waitSeconds % 2 == 0) {
          await _updateUnreadMessagesCount(cubit);
        }
      }
    });
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateUnreadMessagesCount(RideFlowCubit cubit) async {
    try {
      final rideId = cubit.activeRideId;
      if (rideId == null || rideId.isEmpty) return;

      final driverIdentifier =
          await Modular.get<SecureSessionService>().readDriverId() ?? '';
      if (driverIdentifier.isEmpty) return;

      final chatRepo = Modular.get<ChatRepository>();
      final result = await chatRepo.fetchRoomMessages(rideId);
      result.fold((_) => null, (List<ChatMessage> messages) {
        final passengerChatMessagesList =
            messages.where((m) => m.senderId != driverIdentifier).toList();
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
      });
    } catch (_) {}
  }

  String get _waitFormatted {
    final elapsedMinutes = _waitSeconds ~/ 60;
    final elapsedSeconds = _waitSeconds % 60;
    return '${elapsedMinutes.toString().padLeft(2, '0')}:${elapsedSeconds.toString().padLeft(2, '0')}';
  }

  static const double _defaultLat = 7.8286;
  static const double _defaultLng = 123.4361;

  Future<void> _startTrip() async {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowWaitingPassenger
        ? state.passengerName
        : 'Passenger';

    final pickupLat = LocationService.lastPosition?.latitude ?? _defaultLat;
    final pickupLng = LocationService.lastPosition?.longitude ?? _defaultLng;

    double destLat = pickupLat + 0.03;
    double destLng = pickupLng + 0.03;

    try {
      final places = await MapProvider.searchPlaces(widget.dropoff);
      if (places.isNotEmpty) {
        destLat = places.first.latitude;
        destLng = places.first.longitude;
      }
    } catch (_) {}

    if (!mounted) return;

    await BlocProvider.of<RideFlowCubit>(context).startRide(
      passengerName: passengerName,
      destLat: destLat,
      destLng: destLng,
      distanceKm: widget.distance,
    );

    if (mounted) {
      context.pushReplacementNamed(
        TripRoutes.inTransit,
        extra: {
          'pickup': widget.pickup,
          'dropoff': widget.dropoff,
          'distance': widget.distance,
          'fare': widget.fare,
          'duration': widget.duration,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowWaitingPassenger
        ? state.passengerName
        : 'Passenger';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 600.0;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 600.0 : double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
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
                          const Spacer(),
                          _buildStatusBadge(),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: WaitingPassengerPanelWidget(
                            pickup: widget.pickup,
                            dropoff: widget.dropoff,
                            passengerName: passengerName,
                            waitFormatted: _waitFormatted,
                            fare: widget.fare,
                            unreadChatMessagesCount: _unreadChatMessagesCount,
                            onStartTripPressed: _startTrip,
                            onCallPressed: () async {
                              try {
                                final rideId =
                                    BlocProvider.of<RideFlowCubit>(
                                      context,
                                    ).activeRideId ??
                                    '';
                                if (rideId.isNotEmpty) {
                                  final ride =
                                      await Modular.get<TripRemoteDataSource>()
                                          .getRideStatus(rideId);
                                  final passengerId =
                                      ride['passenger_id'] as String?;
                                  if (passengerId != null &&
                                      passengerId.isNotEmpty) {
                                    final passenger =
                                        await Modular.get<
                                          PassengerRemoteDataSource
                                        >().fetchPassengerProfile(passengerId);
                                    final phone =
                                        passenger['phone'] as String?;
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
                            onChatPressed: () async {
                              final rideId =
                                  BlocProvider.of<RideFlowCubit>(
                                    context,
                                  ).activeRideId ??
                                  '';
                              final rState =
                                  BlocProvider.of<RideFlowCubit>(context).state;
                              final pName = rState is RideFlowWaitingPassenger
                                  ? rState.passengerName
                                  : 'Passenger';
                              final cubit = BlocProvider.of<RideFlowCubit>(
                                context,
                              );
                              final driverId =
                                  await Modular.get<SecureSessionService>()
                                      .readDriverId() ??
                                  '';
                              if (!context.mounted) return;
                              setState(() {
                                _unreadChatMessagesCount = 0;
                              });
                              await context.pushNamed(
                                ChatRoutes.chat,
                                extra: {
                                  'roomId': rideId,
                                  'userId': driverId,
                                  'peerName': pName,
                                },
                              );
                              if (!mounted) return;
                              _isInitialChatMessagesCountFetched = false;
                              await _updateUnreadMessagesCount(cubit);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.map_pin_check,
            size: 15,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 8),
          Text(
            "You've Arrived",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
