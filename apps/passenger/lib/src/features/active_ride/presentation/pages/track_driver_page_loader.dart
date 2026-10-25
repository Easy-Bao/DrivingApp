import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/track_driver_page.dart';
import 'package:passenger/src/features/chat/chat.dart';
import 'package:passenger/src/features/home/home_routes.dart';

class TrackDriverPageLoader extends StatefulWidget {
  const TrackDriverPageLoader({
    super.key,
    required this.trackRepository,
    required this.chatRepositoryFactory,
    required this.sessionService,
    required this.lifecycleCoordinator,
    required this.onRideTerminated,
    this.rideId,
    this.realtimeClient,
  });

  final TrackRepository trackRepository;
  final ChatRepositoryFactory chatRepositoryFactory;
  final SessionStore sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final VoidCallback onRideTerminated;
  final String? rideId;
  final RealtimeWebSocketClient? realtimeClient;

  @override
  State<TrackDriverPageLoader> createState() => _TrackDriverPageLoaderState();
}

class _TrackDriverPageLoaderState extends State<TrackDriverPageLoader> {
  bool _isLoading = true;
  RideSnapshot? _ride;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreRide());
  }

  Future<void> _restoreRide() async {
    final requestedRideId = widget.rideId?.trim();
    final activeRideId = requestedRideId == null || requestedRideId.isEmpty
        ? await widget.sessionService.readActiveRideId()
        : requestedRideId;
    if (activeRideId == null || activeRideId.trim().isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final result = await widget.trackRepository.fetchRideResult(
      activeRideId.trim(),
    );
    if (!mounted) return;

    result.fold(
      (_) {
        if (mounted) setState(() => _isLoading = false);
      },
      (snapshot) {
        if (mounted) {
          if (snapshot.isTerminal) {
            unawaited(widget.sessionService.saveActiveRideId(''));
            setState(() => _isLoading = false);
          } else {
            setState(() {
              _ride = snapshot;
              _isLoading = false;
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final ride = _ride;
    if (ride == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ride details aren\'t available.'),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      unawaited(_restoreRide());
                    },
                    icon: const Icon(LucideIcons.refresh_cw, size: 16),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.goNamed(HomeRoutes.home),
                    child: const Text('Return to home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return TrackDriverPage(
      ride: ride,
      trackRepository: widget.trackRepository,
      chatRepositoryFactory: widget.chatRepositoryFactory,
      sessionService: widget.sessionService,
      lifecycleCoordinator: widget.lifecycleCoordinator,
      onRideTerminated: widget.onRideTerminated,
      realtimeClient: widget.realtimeClient,
    );
  }
}
