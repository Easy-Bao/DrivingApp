import 'package:core_models/core_models.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Bloc/RideFlow/RideFlowCubit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'package:shared_ui/shared_ui.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RideFlowCubit>(
      create: (_) {
        return RideFlowCubit(
          repository: Modular.get<RideRepository>(),
          tripRemoteDataSource: Modular.get<TripRemoteDataSource>(),
          sessionService: Modular.get<DriverSessionService>(),
        );
      },
      child: ModularApp.router(
        theme: DriverTheme.themeData,
        darkTheme: DriverTheme.themeData,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        title: 'BaoRide Driver',
      ),
    );
  }
}
