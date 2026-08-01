import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Core/Services/SecureSessionService.dart';
import 'package:passenger_app/src/Features/Trip/Domain/Repositories/ITrackRepository.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Bloc/TrackDriver/TrackDriverCubit.dart';
import 'package:shared_ui/SharedUi.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

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
        theme: PassengerTheme.themeData,
        debugShowCheckedModeBanner: false,
        title: 'BaoRide Passenger',
      ),
    );
  }
}
