import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_state.dart';
import 'package:design_system/design_system.dart';

class const LocationAccessStatusPage({super.key, this.onBack})
    extends StatelessWidget {
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationAccessCubit, LocationAccessViewState>(
      builder: (context, state) {
        final accessState = state is LocationAccessUnavailable
            ? state.accessState
            : null;
        return AppLocationAccessStatusPage(
          presentation: _presentationFor(state),
          onBack: onBack ?? () => context.pop(),
          primaryActionLabel: accessState == null
              ? null
              : _primaryActionLabel(accessState),
          onPrimaryAction: accessState == null
              ? null
              : () => unawaited(
                  BlocProvider.of<LocationAccessCubit>(context).enable(),
                ),
          onRetry: accessState == null
              ? null
              : () => unawaited(
                  BlocProvider.of<LocationAccessCubit>(context).refresh(),
                ),
        );
      },
    );
  }

  static AppLocationAccessPresentation _presentationFor(
    LocationAccessViewState state,
  ) {
    return switch (state) {
      LocationAccessChecking() => const AppLocationAccessPresentation(
        icon: LucideIcons.loader_circle,
        title: 'Checking location access',
        message: 'BaoRide is checking your phone settings and permission.',
        tone: AppLocationAccessTone.neutral,
      ),
      LocationAccessReady() => const AppLocationAccessPresentation(
        icon: LucideIcons.circle_check,
        title: 'Location is ready',
        message:
            'Pickup search and active ride tracking can use your location.',
        tone: AppLocationAccessTone.success,
      ),
      LocationAccessUnavailable(accessState: final accessState) =>
        switch (accessState) {
          LocationAccessState.ready => const AppLocationAccessPresentation(
            icon: LucideIcons.circle_check,
            title: 'Location is ready',
            message:
                'Pickup search and active ride tracking can use your location.',
            tone: AppLocationAccessTone.success,
          ),
          LocationAccessState.serviceDisabled =>
            const AppLocationAccessPresentation(
              icon: LucideIcons.map_pin_off,
              title: 'Location services are off',
              message: 'Turn on your phone location service, then return to BaoRide.',
              tone: AppLocationAccessTone.warning,
            ),
          LocationAccessState.denied => const AppLocationAccessPresentation(
            icon: LucideIcons.shield_alert,
            title: 'Location permission is needed',
            message: 'Allow location when prompted to set an accurate pickup.',
            tone: AppLocationAccessTone.warning,
          ),
          LocationAccessState.deniedForever =>
            const AppLocationAccessPresentation(
              icon: LucideIcons.settings,
              title: 'Location permission is blocked',
              message:
                  'Open app settings and allow location access for BaoRide.',
              tone: AppLocationAccessTone.error,
            ),
        },
    };
  }

  static String _primaryActionLabel(LocationAccessState accessState) {
    return switch (accessState) {
      LocationAccessState.ready => 'Try again',
      LocationAccessState.serviceDisabled => 'Open Location Settings',
      LocationAccessState.denied => 'Allow location',
      LocationAccessState.deniedForever => 'Open App Settings',
    };
  }
}
