import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/location/location_routes.dart';
import 'package:passenger_app/src/features/location/view/widgets/location_access_panel.dart';
import 'package:shared_core/shared_core.dart';

enum _LocationGateState { loading, prompt, unavailable }

class LocationGatePage extends StatefulWidget {
  const LocationGatePage({super.key});

  @override
  State<LocationGatePage> createState() => _LocationGatePageState();
}

class _LocationGatePageState extends State<LocationGatePage>
    with WidgetsBindingObserver {
  _LocationGateState _viewState = _LocationGateState.prompt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resolveInitialAccess());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resolveInitialAccess());
    }
  }

  Future<void> _resolveInitialAccess() async {
    final accessState = await _readAccessState();
    if (!mounted) return;
    if (accessState == LocationAccessState.ready) {
      context.goNamed(HomeRoutes.home);
      return;
    }
    if (_viewState != _LocationGateState.unavailable) {
      setState(() => _viewState = _LocationGateState.prompt);
    }
  }

  Future<LocationAccessState> _readAccessState() async {
    try {
      return await LocationService.getAccessState();
    } catch (_) {
      return LocationAccessState.denied;
    }
  }

  Future<void> _enableLocation() async {
    if (_viewState == _LocationGateState.loading) return;
    setState(() => _viewState = _LocationGateState.loading);

    final accessState = await _readAccessState();
    switch (accessState) {
      case LocationAccessState.denied:
        await LocationService.requestPermission();
      case LocationAccessState.serviceDisabled:
        await LocationService.openLocationSettings();
      case LocationAccessState.deniedForever:
        await LocationService.openAppSettings();
      case LocationAccessState.ready:
        break;
    }

    final refreshedState = await _readAccessState();
    if (!mounted) return;
    if (refreshedState == LocationAccessState.ready) {
      context.goNamed(HomeRoutes.home);
    } else {
      setState(() => _viewState = _LocationGateState.unavailable);
    }
  }

  Future<void> _chooseManualLocation() async {
    final selectedPlace = await context.pushNamed(LocationRoutes.country);
    if (!mounted || selectedPlace is! PlaceModel) return;
    LocationService.setManualLocation(selectedPlace);
    context.goNamed(HomeRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_viewState) {
      _LocationGateState.loading => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      _LocationGateState.prompt => LocationAccessPrompt(
        onEnable: _enableLocation,
        onSkip: () =>
            setState(() => _viewState = _LocationGateState.unavailable),
      ),
      _LocationGateState.unavailable => LocationUnavailableView(
        onUpdateLocation: _chooseManualLocation,
        onContinue: () => context.goNamed(HomeRoutes.home),
      ),
    };
  }
}
