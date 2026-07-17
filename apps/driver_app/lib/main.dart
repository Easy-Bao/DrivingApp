import 'package:driver_app/app_module.dart';
import 'package:driver_app/app_widget.dart';
import 'package:driver_app/src/core/config/environment_config.dart';
import 'package:driver_services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final nativeService = MapNativeServiceImpl();
  LocationService.initialize(nativeService);
  await MapProvider.initialize(
    token: EnvironmentConfig.mapboxPublicToken,
    nativeService: nativeService,
  );



  await BackgroundTelemetryService.initialize();

  await Modular.configure(
    appModule: AppModule(),
    initialRoute: '/',
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    debugLogEventBus: true,
  );

  runApp(const AppWidget());
}
