import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/app/dependencies.dart';
import 'package:passenger/src/core/location/location_access_cubit.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  test('registers booking draft state at the application scope', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final storage = _MockFlutterSecureStorage();
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    final session = SessionStore(storage: storage);
    await dotenv.load(fileName: '.env', isOptional: true);

    await Modular.configure(
      appModule: AppDependencies(
        preferences: preferences,
        sessionService: session,
      ),
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

    final sessionStore = Modular.get<SessionStore>();
    await sessionStore.configurePersistence(rememberMe: false);
    await sessionStore.saveActiveRideId('ride-99');

    final sessionBloc = Modular.get<SessionBloc>()
      ..add(
        const SessionAuthenticatedRequested(
          passengerId: '42',
          passengerName: 'Avery',
        ),
      );
    await Future<void>.delayed(Duration.zero);
    expect(sessionBloc.state, isA<AuthenticatedSession>());

    final provider = Modular.get<RefreshableTokenProvider>();
    await provider.refreshAccessToken();

    expect(provider.isDeferredExpiryPending, isTrue);
    expect(sessionBloc.state, isA<AuthenticatedSession>());

    await sessionStore.saveActiveRideId('');
    await Future<void>.delayed(Duration.zero);

    expect(provider.isDeferredExpiryPending, isFalse);
    expect(sessionBloc.state, const GuestSession());
  });
}
