import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_state.dart';
import 'package:shared_ui/shared_ui.dart';

class LocationGatePage extends StatelessWidget {
  const LocationGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationAccessCubit, LocationAccessViewState>(
      builder: (context, state) => switch (state) {
        LocationAccessChecking() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        LocationAccessReady() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        final LocationAccessUnavailable unavailable => LocationPermissionPage(
          onEnable: () =>
              BlocProvider.of<LocationAccessCubit>(context).enable(),
          onSkip: () {
            BlocProvider.of<LocationAccessCubit>(context).suppressPrompt();
            context.goNamed(HomeRoutes.home);
          },
          statusMessage: unavailable.message,
        ),
      },
    );
  }
}
