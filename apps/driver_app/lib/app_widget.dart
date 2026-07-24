import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_ui/shared_ui.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<RideFlowCubit>(
          create: (_) {
            return RideFlowCubit(
              repository: Modular.get<RideRepository>(),
              tripRemoteDataSource: Modular.get<TripRemoteDataSource>(),
              sessionService: Modular.get<DriverSessionService>(),
            );
          },
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return ModularApp.router(
            theme: AppTheme.lightThemeData,
            darkTheme: AppTheme.lightThemeData,
            themeMode: ThemeMode.light,
            debugShowCheckedModeBanner: false,
            title: 'BaoRide Driver',
          );
        },
      ),
    );
  }
}
