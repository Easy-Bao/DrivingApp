import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/track_driver/track_driver_cubit.dart';
import 'package:session_service/session_service.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TrackDriverCubit>(
          create: (_) {
            return TrackDriverCubit(
              repository: Modular.get<TrackRepository>(),
              sessionService: Modular.get<SecureSessionService>(),
            );
          },
        ),
      ],
      child: ModularApp.router(
        theme: ThemeData(
          useMaterial3: true,
          textTheme: Theme.of(
            context,
          ).textTheme.apply(fontFamily: 'packages/shared_ui/ProductSans'),
        ),
        debugShowCheckedModeBanner: false,
        title: 'BaoRide',
      ),
    );
  }
}
