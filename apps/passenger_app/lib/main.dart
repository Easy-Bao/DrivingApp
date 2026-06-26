import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/app_module.dart';
import 'package:passenger_app/app_widget.dart';
import 'package:passenger_app/core/config/env_config.dart';
import 'package:passenger_app/core/di/service_locator.dart';
import 'package:passenger_app/core/services/map_native_service_impl.dart';
import 'package:passenger_app/core/transitions/app_transitions.dart';
import 'package:passenger_app/src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();
  await dotenv.load(fileName: '.env');

  final nativeService = MapNativeServiceImpl();
  LocationService.initialize(nativeService);
  await MapProvider.initialize(
    token: EnvConfig.mapboxPublicToken,
    nativeService: nativeService,
  );

  setupServiceLocator();

  /**
   * Apply globally snappy transition timing before the router initializes.
   * 160ms easeOutCubic replaces the default 300ms linear curve across all routes.
   */
  AppTransitions.configure();

  await Modular.configure(
    appModule: AppModule(),
    initialRoute: '/',
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    debugLogEventBus: true,
  );

  runApp(const AppWidget());
}
