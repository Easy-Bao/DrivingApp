import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/app_module.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/domain/repositories/i_location_access_repository.dart';
import 'package:passenger_app/src/features/trip/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('registers booking draft state at the application scope', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{
      appThemeModePreferenceKey: 'dark',
    });
    final preferences = await SharedPreferences.getInstance();

    await Modular.configure(
      appModule: AppModule(prefs: preferences),
      initialRoute: HomeRoutes.fullHomePath,
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
    );
    await Future<void>.delayed(Duration.zero);

    expect(Modular.isRegistered<BookingDraftCubit>(), isTrue);
    expect(Modular.isRegistered<SessionBloc>(), isTrue);
    expect(Modular.isRegistered<ILocationAccessRepository>(), isTrue);
    expect(Modular.isRegistered<LocationAccessCubit>(), isTrue);
    expect(Modular.isRegistered<ThemeModeCubit>(), isTrue);
    expect(Modular.get<BookingDraftCubit>(), isA<BookingDraftCubit>());
    expect(Modular.get<ThemeModeCubit>().state, ThemeMode.dark);

    expect(
      Modular.routerConfig.namedLocation(AuthRoutes.signin),
      AuthRoutes.signinPath,
    );
  });
}
