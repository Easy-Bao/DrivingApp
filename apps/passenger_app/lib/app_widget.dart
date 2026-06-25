import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/core/di/service_locator.dart';
import 'package:core_models/core_models.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/finding_driver/finding_driver_bloc.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/track_driver/track_driver_cubit.dart';

/// Note: DashboardCubit and PassengerHomeCubit are provided at the route
/// level in their respective modules (DashboardModule, HomeModule) so they
/// can be scoped to their screens and re-created on each visit.
class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // FindingDriverBloc spans the finding → matched flow.
        BlocProvider<FindingDriverBloc>(
          create: (_) {
            // NOTE: getIt<DriverRepository>() automatically injects the active implementation
                        // (e.g. FixtureDriverRepository, or _ApiDriverRepository when backend is ready).
            return FindingDriverBloc(repository: getIt<DriverRepository>());
          },
        ),

        // TrackDriverCubit spans the activity tracking flow.
        BlocProvider<TrackDriverCubit>(
          create: (_) {
            // NOTE: getIt<TrackRepository>() automatically injects the active implementation
            // (e.g. FixtureTrackRepository, or _ApiTrackRepository when backend is ready).
            return TrackDriverCubit(repository: getIt<TrackRepository>());
          },
        ),
      ],
      child: ModularApp.router(
        theme: ThemeData(
          useMaterial3: true,
          textTheme: Theme.of(
            context,
          ).textTheme.apply(fontFamily: 'ProductSans'),
        ),
        debugShowCheckedModeBanner: false,
        title: 'BaoRide',
      ),
    );
  }
}
