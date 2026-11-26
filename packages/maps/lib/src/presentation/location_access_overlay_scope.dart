import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/src/domain/entities/location_access_state.dart';
import 'package:maps/src/presentation/location_access_cubit.dart';
import 'package:maps/src/presentation/location_access_state.dart';
import 'package:material_ui/material_ui.dart';

/// Mounts the location recovery overlay above [child] while isolating
/// [LocationAccessCubit] rebuilds from the underlying navigator subtree.
class LocationAccessOverlayScope extends StatelessWidget {
  const LocationAccessOverlayScope({
    super.key,
    required this.enabled,
    required this.child,
    this.appName = 'EasyRide',
  });

  final bool enabled;
  final Widget child;
  final String appName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (enabled)
          BlocBuilder<LocationAccessCubit, LocationAccessViewState>(
            builder: (context, locationState) {
              return _buildOverlay(context, locationState) ??
                  const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget? _buildOverlay(
    BuildContext context,
    LocationAccessViewState locationState,
  ) {
    final cubit = BlocProvider.of<LocationAccessCubit>(context);
    return switch (locationState) {
      LocationAccessChecking() => LocationAccessOverlay(
        state: LocationAccessOverlayState.checking,
        appName: appName,
      ),
      LocationAccessReady() => null,
      LocationAccessUnavailable(
        accessState: final accessState,
        message: final message,
      ) =>
        switch (accessState) {
          LocationAccessState.ready => null,
          LocationAccessState.denied => LocationAccessOverlay(
            state: LocationAccessOverlayState.permissionDenied,
            appName: appName,
            message: message,
            onTryAgain: () => unawaited(cubit.enable()),
          ),
          LocationAccessState.serviceDisabled => LocationAccessOverlay(
            state: LocationAccessOverlayState.serviceDisabled,
            appName: appName,
            message: message,
            onOpenLocationSettings: () => unawaited(cubit.enable()),
            onTryAgain: () => unawaited(cubit.refresh()),
          ),
          LocationAccessState.deniedForever => LocationAccessOverlay(
            state: LocationAccessOverlayState.permissionDeniedForever,
            appName: appName,
            message: message,
            onOpenAppSettings: () => unawaited(cubit.enable()),
            onTryAgain: () => unawaited(cubit.refresh()),
          ),
        },
    };
  }
}
