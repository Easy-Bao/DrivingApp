import 'dart:async';

import 'package:chat/chat.dart';
import 'package:core_domain/core_domain.dart';
import 'package:design_system/design_system.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/track_driver_page.dart';
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
  String? _errorMessage;

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
      if (mounted) {
        setState(() {
          _errorMessage = null;
          _isLoading = false;
        });
      }
      return;
    }

    final result = await widget.trackRepository.fetchRideResult(
      activeRideId.trim(),
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _errorMessage = ErrorHandler.getErrorMessage(failure);
            _isLoading = false;
          });
        }
      },
      (snapshot) {
        if (mounted) {
          if (snapshot.isTerminal) {
            unawaited(widget.sessionService.saveActiveRideId(''));
            setState(() {
              _errorMessage = null;
              _isLoading = false;
            });
          } else {
            setState(() {
              _ride = snapshot;
              _errorMessage = null;
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
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(HomeRoutes.home);
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final ride = _ride;
    if (ride == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(HomeRoutes.home);
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: AppRetryErrorView(
          title: 'Could not load trip',
          message: _errorMessage ?? 'No active trip was found.',
          onRetry: () {
            setState(() {
              _errorMessage = null;
              _isLoading = true;
            });
            unawaited(_restoreRide());
          },
          secondaryAction: TextButton(
            onPressed: () => context.goNamed(HomeRoutes.home),
            child: const Text('Return to home'),
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
