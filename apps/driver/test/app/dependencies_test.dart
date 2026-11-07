import 'package:driver/src/app/dependencies.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:driver/src/core/location/location_access_cubit.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestSessionStore extends SessionStore {
  bool sessionCleared = false;
  String? activeRideId;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<String?> readActiveRideId() async => activeRideId;

  @override
  Future<void> clearActiveRideId() async {
    activeRideId = null;
    await notifyActiveRideCleared();
  }

  @override
  Future<void> clearSession() async => sessionCleared = true;
}

void main() {
  test('routes to sign-in when the refresh session expires', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = TestSessionStore();
    await dotenv.load(fileName: '.env', isOptional: true);

    await Modular.configure(
      appModule: AppDependencies(
        preferences: preferences,
        sessionService: session,
      ),
      initialRoute: DashboardRoutes.fullDashboardPath,
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
    );
    await Future<void>.delayed(Duration.zero);

    expect(Modular.isRegistered<LocationAccessRepository>(), isTrue);
    expect(Modular.isRegistered<LocationAccessCubit>(), isTrue);

    await Modular.get<RefreshableTokenProvider>().refreshAccessToken();

    expect(session.sessionCleared, isTrue);
    expect(
      Modular.routerConfig.routeInformationProvider.value.uri.path,
      AuthRoutes.signinPath,
    );

    // Verify deferred expiry during an active ride and flush when cleared
    session
      ..sessionCleared = false
      ..activeRideId = 'ride-123';
    Modular.routerConfig.go(DashboardRoutes.fullDashboardPath);
    await Future<void>.delayed(Duration.zero);

    final provider = Modular.get<RefreshableTokenProvider>();
    await provider.refreshAccessToken();

    expect(provider.isDeferredExpiryPending, isTrue);
    expect(session.sessionCleared, isFalse);

    await session.clearActiveRideId();

    expect(provider.isDeferredExpiryPending, isFalse);
    expect(session.sessionCleared, isTrue);
    expect(
      Modular.routerConfig.routeInformationProvider.value.uri.path,
      AuthRoutes.signinPath,
    );
  });
}
