import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';

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
    return BlocProvider<TrackDriverCubit>(
      create: (_) {
        return TrackDriverCubit(
          repository: Modular.get<ITrackRepository>(),
          sessionService: Modular.get<SecureSessionService>(),
        );
      },
      child: ModularApp.router(
        theme: AppTheme.themeData,
        debugShowCheckedModeBanner: false,
        title: 'BaoRide Passenger',
      ),
    );
  }
}
