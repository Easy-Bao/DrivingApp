import 'package:driver/src/app/driver_dependencies.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver/src/features/location/domain/repositories/driver_location_access_repository.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestDriverSessionStore extends DriverSessionStore {
  bool sessionCleared = false;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> clearSession() async => sessionCleared = true;
}

void main() {
  test('routes to sign-in when the refresh session expires', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = TestDriverSessionStore();
    await dotenv.load(fileName: '.env', isOptional: true);

    await Modular.configure(
      appModule: DriverDependencies(
        prefs: preferences,
        sessionService: session,
      ),
      initialRoute: DashboardRoutes.fullDashboardPath,
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
    );
    await Future<void>.delayed(Duration.zero);

    expect(Modular.isRegistered<DriverLocationAccessRepository>(), isTrue);
    expect(Modular.isRegistered<DriverLocationAccessCubit>(), isTrue);

    await Modular.get<RefreshableTokenProvider>().refreshAccessToken();

    expect(session.sessionCleared, isTrue);
    expect(
      Modular.routerConfig.routeInformationProvider.value.uri.path,
      AuthRoutes.signinPath,
    );
  });
}
