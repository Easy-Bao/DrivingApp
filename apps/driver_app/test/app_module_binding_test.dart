import 'package:driver_app/app_module.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test(
    'registers the persisted appearance mode at application scope',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(<String, Object>{
        appThemeModePreferenceKey: 'dark',
      });
      final preferences = await SharedPreferences.getInstance();

      await Modular.configure(
        appModule: AppModule(prefs: preferences),
        initialRoute: AuthRoutes.signinPath,
        debugLogDiagnostics: false,
        debugLogDiagnosticsGoRouter: false,
        debugLogEventBus: false,
      );
      await Future<void>.delayed(Duration.zero);

      expect(Modular.isRegistered<ThemeModeCubit>(), isTrue);
      expect(Modular.get<ThemeModeCubit>().state, ThemeMode.dark);
    },
  );
}
