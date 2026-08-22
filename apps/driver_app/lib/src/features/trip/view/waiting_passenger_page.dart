import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';

import 'dart:async';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
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
  int _unreadChatMessagesCount = 0;
  int _viewedPassengerMessagesCount = 0;
  bool _isInitialChatMessagesCountFetched = false;
  bool _isStartingTrip = false;
  bool _isPollingChat = false;
  Timer? _chatPollTimer;
  ChatRepository? _chatRepository;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final cubit = BlocProvider.of<RideFlowCubit>(context);
    unawaited(_initializeChatRepository(cubit));
    _chatPollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(_updateUnreadMessagesCount(cubit)),
    );
    unawaited(_updateUnreadMessagesCount(cubit));
  }

  Future<void> _initializeChatRepository(RideFlowCubit cubit) async {
    final driverIdentifier =
        await Modular.get<SecureSessionService>().readDriverId() ?? '';
    if (!mounted || driverIdentifier.isEmpty) return;
    _chatRepository = ChatRepository(
      remoteDataSource: WebSocketChatRemoteDataSource(),
      currentUserId: driverIdentifier,
      clientDio: Modular.get<Dio>(),
    );
    unawaited(_updateUnreadMessagesCount(cubit));
  }

  @override
  void dispose() {
    _chatPollTimer?.cancel();
    unawaited(_chatRepository?.dispose());
    super.dispose();
  }

  Future<void> _updateUnreadMessagesCount(RideFlowCubit cubit) async {
    if (_isPollingChat) return;
    _isPollingChat = true;
    try {
      final rideId = cubit.activeRideId;
      if (rideId == null || rideId.isEmpty) return;

      final driverIdentifier =
          await Modular.get<SecureSessionService>().readDriverId() ?? '';
      if (driverIdentifier.isEmpty) return;

      final chatRepo = _chatRepository;
      if (chatRepo == null) return;
      final result = await chatRepo.fetchRoomMessages(rideId);
      result.fold((_) => null, (List<ChatMessage> messages) {
        final passengerChatMessagesList = messages
            .where((m) => m.senderId != driverIdentifier)
            .toList();
        final currentPassengerMessagesCount = passengerChatMessagesList.length;

        if (!_isInitialChatMessagesCountFetched) {
          // Existing passenger messages are unread until this chat is opened.
          _viewedPassengerMessagesCount = 0;
          _isInitialChatMessagesCountFetched = true;
        }
        final unreadCount =
            (currentPassengerMessagesCount - _viewedPassengerMessagesCount)
                .clamp(0, currentPassengerMessagesCount)
                .toInt();
        if (mounted && unreadCount != _unreadChatMessagesCount) {
          setState(() => _unreadChatMessagesCount = unreadCount);
        }
      });
    } catch (error) {
      dev.log('Unable to refresh passenger chat count: $error');
    } finally {
      _isPollingChat = false;
    }
  }

  String _formatWaitDuration(int elapsedSeconds) {
    final elapsedMinutes = elapsedSeconds ~/ 60;
    final remainingSeconds = elapsedSeconds % 60;
    return '${elapsedMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
      final rideCubit = BlocProvider.of<RideFlowCubit>(context);
      final started = await rideCubit.startRide(
        passengerName: state.passengerName,
        destLat: state.destLat,
        destLng: state.destLng,
        distanceKm: widget.distance,
        passengerLat: state.pickupLat,
        passengerLng: state.pickupLng,
      );

      if (mounted && !started) {
        final errorState = rideCubit.state;
        _showError(
          errorState is RideFlowError
              ? errorState.message
              : 'Unable to Start The Trip Right Now. Please Try Again.',
        );
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
      dev.log('Unable to start trip: $error');
      _showError('Unable To Start The Trip Right Now. Please Try Again.');
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
    final state = context.watch<RideFlowCubit>().state;
    final passengerName = state is RideFlowWaitingPassenger
        ? state.passengerName
        : '—';
    final waitFormatted = state is RideFlowWaitingPassenger
        ? _formatWaitDuration(state.waitTimeSeconds)
        : '00:00';

    return Scaffold(
      backgroundColor: AppTheme.background,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTripBackButton(context, () => context.pop()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              WaitingPassengerPanelWidget(
                                pickup: widget.pickup,
                                dropoff: widget.dropoff,
                                passengerName: passengerName,
                                waitFormatted: waitFormatted,
                                fare: widget.fare,
                                includeStartTripButton: false,
                                unreadChatMessagesCount:
                                    _unreadChatMessagesCount,
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
                                          await Modular.get<
                                                TripRemoteDataSource
                                              >()
                                              .getRideStatus(rideId);
                                      final passengerId = driverValueAsString(
                                        ride['passenger_id'],
                                      );
                                      if (passengerId != null &&
                                          passengerId.isNotEmpty) {
                                        final passenger =
                                            await Modular.get<
                                                  PassengerRemoteDataSource
                                                >()
                                                .fetchPassengerProfile(
                                                  passengerId,
                                                );
                                        final phone = driverValueAsString(
                                          passenger['phone'],
                                        );
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
                                    _showError(
                                      'Unable to contact the passenger.',
                                    );
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
                                  final pName =
                                      rState is RideFlowWaitingPassenger
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
                                    _viewedPassengerMessagesCount +=
                                        _unreadChatMessagesCount;
                                    _unreadChatMessagesCount = 0;
                                    _isInitialChatMessagesCountFetched = true;
                                  });
                                  await context.pushNamed(
                                    ChatRoutes.chat,
                                    extra: {
                                      'roomId': rideId,
                                      'userId': driverId,
                                      'peerId': cubit.activePassengerId,
                                      'peerName': pName,
                                    },
                                  );
                                  if (!mounted) return;
                                  await _updateUnreadMessagesCount(cubit);
                                },
                              ),
                              const Spacer(),
                              WaitingPassengerStartTripButton(
                                isStartingTrip: _isStartingTrip,
                                onPressed: _startTrip,
                              ),
                            ],
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

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: AppTheme.surface,
      elevation: 2,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor),
          ),
        ),
      ),
    ),
  );
}
