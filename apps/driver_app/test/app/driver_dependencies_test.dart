import 'package:driver_app/src/app/driver_dependencies.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/domain/repositories/i_driver_location_access_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'registers driver application dependencies at application scope',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();

      await Modular.configure(
        appModule: DriverDependencies(prefs: preferences),
        initialRoute: AuthRoutes.signinPath,
        debugLogDiagnostics: false,
        debugLogDiagnosticsGoRouter: false,
        debugLogEventBus: false,
      );
      await Future<void>.delayed(Duration.zero);

      expect(Modular.isRegistered<IDriverLocationAccessRepository>(), isTrue);
      expect(Modular.isRegistered<DriverLocationAccessCubit>(), isTrue);
    },
  );
}
