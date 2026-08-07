import 'dart:async';

import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

enum _DriverLocationGateState { checking, prompt }

class DriverLocationGatePage extends StatefulWidget {
  const DriverLocationGatePage({super.key});

  @override
  State<DriverLocationGatePage> createState() => _DriverLocationGatePageState();
}

class _DriverLocationGatePageState extends State<DriverLocationGatePage>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 2);

  _DriverLocationGateState _viewState = _DriverLocationGateState.checking;
  Timer? _accessPoller;
  String? _statusMessage;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAccessMonitoring();
      unawaited(_refreshAccess());
    });
  }

  @override
  void dispose() {
    _accessPoller?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAccess());
    }
  }

  void _startAccessMonitoring() {
    _accessPoller ??= Timer.periodic(
      _pollInterval,
      (_) => unawaited(_refreshAccess()),
    );
  }

  void _stopAccessMonitoring() {
    _accessPoller?.cancel();
    _accessPoller = null;
  }

  Future<void> _refreshAccess() async {
    if (!mounted || _isChecking) return;
    _isChecking = true;
    try {
      final accessState = await LocationService.getAccessState();
      if (!mounted) return;
      if (accessState == LocationAccessState.ready) {
        _stopAccessMonitoring();
        context.goNamed(HomeRoutes.dashboard);
        return;
      }
      if (_viewState != _DriverLocationGateState.prompt) {
        setState(() => _viewState = _DriverLocationGateState.prompt);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _viewState = _DriverLocationGateState.prompt;
        _statusMessage = 'Location is temporarily unavailable. Try again.';
      });
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _enableLocation() async {
    if (_isChecking) return;
    setState(() {
      _viewState = _DriverLocationGateState.checking;
      _statusMessage = null;
    });
    _isChecking = true;

    try {
      final accessState = await LocationService.getAccessState();
      switch (accessState) {
        case LocationAccessState.denied:
          await LocationService.requestPermission();
          break;
        case LocationAccessState.serviceDisabled:
          await LocationService.openLocationSettings();
          _showSettingsReturnMessage();
          return;
        case LocationAccessState.deniedForever:
          await LocationService.openAppSettings();
          _showSettingsReturnMessage();
          return;
        case LocationAccessState.ready:
          break;
      }

      final refreshedState = await LocationService.getAccessState();
      if (!mounted) return;
      if (refreshedState == LocationAccessState.ready) {
        _stopAccessMonitoring();
        context.goNamed(HomeRoutes.dashboard);
      } else {
        setState(() {
          _viewState = _DriverLocationGateState.prompt;
          _statusMessage = 'Location access is still off. You can try again.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _viewState = _DriverLocationGateState.prompt;
        _statusMessage = 'Location is temporarily unavailable. Try again.';
      });
    } finally {
      _isChecking = false;
    }
  }

  void _showSettingsReturnMessage() {
    _isChecking = false;
    if (!mounted) return;
    _startAccessMonitoring();
    setState(() {
      _viewState = _DriverLocationGateState.prompt;
      _statusMessage = 'Turn on location in Settings, then return to BaoRide.';
    });
  }

  void _skipLocation() {
    _stopAccessMonitoring();
    context.goNamed(HomeRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_viewState) {
      _DriverLocationGateState.checking => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      _DriverLocationGateState.prompt => LocationPermissionPage(
        onEnable: _enableLocation,
        onSkip: _skipLocation,
        statusMessage: _statusMessage,
      ),
    };
  }
}
