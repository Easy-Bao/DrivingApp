import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_state.dart';
import 'package:shared_ui/shared_ui.dart';

class LocationAccessStatusPage extends StatelessWidget {
  final VoidCallback? onBack;

  const LocationAccessStatusPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack ?? () => context.pop(),
          icon: const Icon(LucideIcons.arrow_left),
        ),
        title: const Text('Location access'),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: BlocBuilder<LocationAccessCubit, LocationAccessViewState>(
            builder: (context, state) {
              final presentation = _presentationFor(state);
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: context.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: presentation
                                .color(context)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            presentation.icon,
                            size: 30,
                            color: presentation.color(context),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          presentation.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          presentation.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (state case LocationAccessUnavailable(
                    accessState: final accessState,
                  )) ...[
                    FilledButton(
                      onPressed: () => unawaited(
                        BlocProvider.of<LocationAccessCubit>(context).enable(),
                      ),
                      child: Text(_primaryActionLabel(accessState)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => unawaited(
                        BlocProvider.of<LocationAccessCubit>(context).refresh(),
                      ),
                      child: const Text('Try again'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Why BaoRide needs location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const _LocationReason(
                    icon: LucideIcons.map_pin,
                    title: 'Accurate pickup points',
                    message: 'Place your pickup where drivers can find you.',
                  ),
                  const SizedBox(height: 10),
                  const _LocationReason(
                    icon: LucideIcons.navigation,
                    title: 'Live trip progress',
                    message:
                        'Keep active ride routes and arrival updates useful.',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static _LocationPresentation _presentationFor(LocationAccessViewState state) {
    return switch (state) {
      LocationAccessChecking() => const _LocationPresentation(
        icon: LucideIcons.loader_circle,
        title: 'Checking location access',
        message: 'BaoRide is checking your phone settings and permission.',
        tone: _LocationTone.neutral,
      ),
      LocationAccessReady() => const _LocationPresentation(
        icon: LucideIcons.circle_check,
        title: 'Location is ready',
        message:
            'Pickup search and active ride tracking can use your location.',
        tone: _LocationTone.success,
      ),
      LocationAccessUnavailable(accessState: final accessState) =>
        switch (accessState) {
          LocationAccessState.ready => const _LocationPresentation(
            icon: LucideIcons.circle_check,
            title: 'Location is ready',
            message:
                'Pickup search and active ride tracking can use your location.',
            tone: _LocationTone.success,
          ),
          LocationAccessState.serviceDisabled => const _LocationPresentation(
            icon: LucideIcons.map_pin_off,
            title: 'Location services are off',
            message:
                'Turn on your phone location service, then return to BaoRide.',
            tone: _LocationTone.warning,
          ),
          LocationAccessState.denied => const _LocationPresentation(
            icon: LucideIcons.shield_alert,
            title: 'Location permission is needed',
            message: 'Allow location when prompted to set an accurate pickup.',
            tone: _LocationTone.warning,
          ),
          LocationAccessState.deniedForever => const _LocationPresentation(
            icon: LucideIcons.settings,
            title: 'Location permission is blocked',
            message: 'Open app settings and allow location access for BaoRide.',
            tone: _LocationTone.error,
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

enum _LocationTone { neutral, success, warning, error }

class _LocationPresentation {
  final IconData icon;
  final String title;
  final String message;
  final _LocationTone tone;

  const _LocationPresentation({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
  });

  Color color(BuildContext context) {
    return switch (tone) {
      _LocationTone.neutral => context.colorScheme.onSurfaceVariant,
      _LocationTone.success => context.semanticColors.success,
      _LocationTone.warning => context.semanticColors.warning,
      _LocationTone.error => context.colorScheme.error,
    };
  }
}

class _LocationReason extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _LocationReason({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: context.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 3),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
