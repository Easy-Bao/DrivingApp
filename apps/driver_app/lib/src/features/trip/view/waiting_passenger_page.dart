import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';

import 'dart:async';
import 'dart:developer' as dev;

import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/chat/chat_routes.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver_app/src/features/trip/view/widgets/waiting_passenger_panel_widget.dart';
import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/datasources/passenger_remote_data_source.dart';
import 'package:url_launcher/url_launcher.dart';

class WaitingPassengerPage extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;

  const WaitingPassengerPage({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<WaitingPassengerPage> createState() => _WaitingPassengerPageState();
}

class _WaitingPassengerPageState extends State<WaitingPassengerPage> {
  int _waitSeconds = 0;
  Timer? _waitTimer;

  int _unreadChatMessagesCount = 0;
  int _viewedPassengerMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;
  bool _isStartingTrip = false;
  String? _errorMessage;

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
        final passengerChatMessagesList = messages
            .where((m) => m.senderId != driverIdentifier)
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
      });
    } catch (error) {
      dev.log('Unable to refresh passenger chat count: $error');
    }
  }

  String get _waitFormatted {
    final elapsedMinutes = _waitSeconds ~/ 60;
    final elapsedSeconds = _waitSeconds % 60;
    return '${elapsedMinutes.toString().padLeft(2, '0')}:${elapsedSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startTrip() async {
    if (_isStartingTrip) return;
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    if (state is! RideFlowWaitingPassenger ||
        state.pickupLat == null ||
        state.pickupLng == null) {
      _showError('Passenger pickup coordinates are unavailable.');
      return;
    }

    setState(() => _isStartingTrip = true);
    try {
      var destinationLat = state.destLat;
      var destinationLng = state.destLng;
      if (destinationLat == null || destinationLng == null) {
        final places = await MapProvider.searchPlaces(widget.dropoff);
        if (places.isEmpty) {
          _showError('The destination could not be located.');
          return;
        }
        destinationLat = places.first.latitude;
        destinationLng = places.first.longitude;
      }

      if (!mounted) return;

      final started = await BlocProvider.of<RideFlowCubit>(context).startRide(
        passengerName: state.passengerName,
        destLat: destinationLat,
        destLng: destinationLng,
        distanceKm: widget.distance,
        passengerLat: state.pickupLat,
        passengerLng: state.pickupLng,
      );

      if (mounted && !started) {
        _showError('Unable to start the trip right now. Please try again.');
      }
      if (mounted && started) {
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
    } catch (error) {
      dev.log('Unable to resolve trip destination: $error');
      _showError('Unable to start the trip right now. Please try again.');
    } finally {
      if (mounted) setState(() => _isStartingTrip = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowWaitingPassenger
        ? state.passengerName
        : '—';

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
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          child: WaitingPassengerPanelWidget(
                            pickup: widget.pickup,
                            dropoff: widget.dropoff,
                            passengerName: passengerName,
                            waitFormatted: _waitFormatted,
                            fare: widget.fare,
                            isStartingTrip: _isStartingTrip,
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
                                            >()
                                            .fetchPassengerProfile(passengerId);
                                    final phone = passenger['phone'] as String?;
                                    if (phone != null && phone.isNotEmpty) {
                                      final uri = Uri.parse('tel:$phone');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    }
                                  }
                                }
                              } catch (error) {
                                dev.log('Unable to call passenger: $error');
                                _showError('Unable to contact the passenger.');
                              }
                            },
                            onChatPressed: () async {
                              final rideId =
                                  BlocProvider.of<RideFlowCubit>(
                                    context,
                                  ).activeRideId ??
                                  '';
                              final rState = BlocProvider.of<RideFlowCubit>(
                                context,
                              ).state;
                              final pName = rState is RideFlowWaitingPassenger
                                  ? rState.passengerName
                                  : '—';
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

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cancel.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.cancel,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
