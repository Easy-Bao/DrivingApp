import 'dart:async';

import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverLocationAccessStatusPage extends StatelessWidget {
  const DriverLocationAccessStatusPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      DriverLocationAccessCubit,
      DriverLocationAccessViewState
    >(
      builder: (context, state) {
        final accessState = state is DriverLocationAccessUnavailable
            ? state.accessState
            : null;
        return AppLocationAccessStatusPage(
          presentation: _presentationFor(state),
          audience: 'driver availability and active trip tracking',
          onBack: onBack ?? () => context.pop(),
          primaryActionLabel: accessState == null
              ? null
              : _primaryActionLabel(accessState),
          onPrimaryAction: accessState == null
              ? null
              : () => unawaited(
                  BlocProvider.of<DriverLocationAccessCubit>(context).enable(),
                ),
          onRetry: accessState == null
              ? null
              : () => unawaited(
                  BlocProvider.of<DriverLocationAccessCubit>(context).refresh(),
                ),
        );
      },
    );
  }

  static AppLocationAccessPresentation _presentationFor(
    DriverLocationAccessViewState state,
  ) {
    return switch (state) {
      DriverLocationAccessChecking() => const AppLocationAccessPresentation(
        icon: LucideIcons.loader_circle,
        title: 'Checking location access',
        message: 'BaoRide is checking your phone settings and permission.',
        tone: AppLocationAccessTone.neutral,
      ),
      DriverLocationAccessReady() => const AppLocationAccessPresentation(
        icon: LucideIcons.circle_check,
        title: 'Location is ready',
        message: 'You can go online and receive nearby ride requests.',
        tone: AppLocationAccessTone.success,
      ),
      DriverLocationAccessUnavailable(accessState: final accessState) =>
        switch (accessState) {
          LocationAccessState.ready => const AppLocationAccessPresentation(
            icon: LucideIcons.circle_check,
            title: 'Location is ready',
            message: 'You can go online and receive nearby ride requests.',
            tone: AppLocationAccessTone.success,
          ),
          LocationAccessState.serviceDisabled =>
            const AppLocationAccessPresentation(
              icon: LucideIcons.map_pin_off,
              title: 'Location services are off',
              message:
                  'Turn on your phone location service before going online.',
              tone: AppLocationAccessTone.warning,
            ),
          LocationAccessState.denied => const AppLocationAccessPresentation(
            icon: LucideIcons.shield_alert,
            title: 'Location permission is needed',
            message:
                'Allow location when prompted so BaoRide can send nearby rides.',
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
