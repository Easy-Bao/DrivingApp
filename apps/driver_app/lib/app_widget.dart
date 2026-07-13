import 'package:driver_app/src/core/di/service_locator.dart';
import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/ride/ride_flow_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'package:driver_app/src/core/services/trip_api_service.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RideFlowCubit>(
          create: (_) {
            return RideFlowCubit(
              repository: getIt<RideRepository>(),
              apiService: getIt<TripApiService>(),
            );
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
        title: 'BaoRide Driver',
      ),
    );
  }
}
