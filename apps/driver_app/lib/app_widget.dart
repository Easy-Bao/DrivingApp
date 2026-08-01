import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/data_sources/trip_remote_data_source.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
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
          tripRemoteDataSource: Modular.get<TripRemoteDataSource>(),
          sessionService: Modular.get<SecureSessionService>(),
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
