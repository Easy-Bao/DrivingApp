import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/app_module.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('registers booking draft state at the application scope', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    await Modular.configure(
      appModule: AppModule(prefs: preferences),
      initialRoute: '/passenger/home',
      debugLogDiagnostics: false,
      debugLogDiagnosticsGoRouter: false,
      debugLogEventBus: false,
    );
    await Future<void>.delayed(Duration.zero);

    expect(Modular.isRegistered<BookingDraftCubit>(), isTrue);
    expect(Modular.isRegistered<SessionBloc>(), isTrue);
    expect(Modular.get<BookingDraftCubit>(), isA<BookingDraftCubit>());

    expect(Modular.routerConfig.namedLocation('Signin'), '/auth/signin');
  });
}
