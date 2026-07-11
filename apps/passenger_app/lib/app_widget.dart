import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/track_driver/track_driver_cubit.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // TrackDriverCubit spans the activity tracking flow.
        BlocProvider<TrackDriverCubit>(
          create: (_) {
            // NOTE: getIt<TrackRepository>() automatically injects the active TrackRepositoryImpl.
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
