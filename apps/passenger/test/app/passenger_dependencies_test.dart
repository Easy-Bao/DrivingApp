import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/app/passenger_dependencies.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/location/domain/repositories/location_access_repository.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('registers booking draft state at the application scope', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    await Modular.configure(
      appModule: PassengerDependencies(prefs: preferences),
      initialRoute: HomeRoutes.fullHomePath,
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
    );
    await Future<void>.delayed(Duration.zero);

    expect(Modular.isRegistered<BookingDraftCubit>(), isTrue);
    expect(Modular.isRegistered<SessionBloc>(), isTrue);
    expect(Modular.isRegistered<LocationAccessRepository>(), isTrue);
    expect(Modular.isRegistered<LocationAccessCubit>(), isTrue);
    expect(Modular.get<BookingDraftCubit>(), isA<BookingDraftCubit>());

    expect(
      Modular.routerConfig.namedLocation(AuthRoutes.signin),
      AuthRoutes.signinPath,
    );
  });
}
