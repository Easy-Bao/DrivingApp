import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/LocationService.dart';
import 'package:passenger_app/AppModule.dart';
import 'package:passenger_app/AppWidget.dart';

import 'package:passenger_app/src/Core/Constants/EnvConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/SharedUi.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  await dotenv.load(fileName: '.env');

  final nativeService = MapNativeService(
    placeServiceBaseUri: EnvConfig.placeServiceUri,
  );
  LocationService.initialize(nativeService);
  await MapProvider.initialize(
    token: EnvConfig.mapboxPublicToken,
    nativeService: nativeService,
  );

  AppTransitions.configure();

  await Modular.configure(
    appModule: AppModule(prefs: prefs),
    initialRoute: '/',
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    debugLogEventBus: true,
  );

  runApp(const AppWidget());
}
