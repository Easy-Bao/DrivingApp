import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'features/passenger/data/repositories/driver_repository.dart';
import 'features/driver/data/repositories/ride_repository.dart';
import 'features/passenger/presentation/bloc/finding_driver/finding_driver_bloc.dart';
import 'features/passenger/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'features/passenger/presentation/bloc/home/passenger_home_cubit.dart';
import 'features/driver/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'features/driver/presentation/bloc/ride/ride_flow_cubit.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DriverRepository>(
          create: (_) => DriverRepositoryImpl(),
        ),
        RepositoryProvider<RideRepository>(
          create: (_) => RideRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<FindingDriverBloc>(
            create: (context) => FindingDriverBloc(
              driverRepository: RepositoryProvider.of<DriverRepository>(context),
            ),
          ),
          BlocProvider<TrackDriverCubit>(
            create: (_) => TrackDriverCubit(),
          ),
          BlocProvider<PassengerHomeCubit>(
            create: (_) => PassengerHomeCubit(),
          ),
          BlocProvider<DashboardCubit>(
            create: (context) => DashboardCubit(
              rideRepository: RepositoryProvider.of<RideRepository>(context),
            ),
          ),
          BlocProvider<RideFlowCubit>(
            create: (context) => RideFlowCubit(
              rideRepository: RepositoryProvider.of<RideRepository>(context),
            ),
          ),
        ],
        child: ModularApp.router(
          theme: ThemeData(
            useMaterial3: true,
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'ProductSans'),
          ),
          debugShowCheckedModeBanner: false,
          title: 'BaoRide',
        ),
      ),
    );
  }
}
