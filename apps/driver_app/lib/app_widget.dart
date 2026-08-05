import 'dart:async';

import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';

import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(LocationService.refresh());
    }
  }

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
        theme: AppTheme.themeData,
        darkTheme: AppTheme.themeData,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        title: 'BaoRide Driver',
      ),
    );
  }
}
