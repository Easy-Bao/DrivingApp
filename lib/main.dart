import 'package:BaoRide/app_module.dart';
import 'package:BaoRide/app_widget.dart';
import 'package:BaoRide/core/di/service_locator.dart';
import 'package:BaoRide/core/services/map_provider.dart';
import 'package:BaoRide/src/rust/frb_generated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();
  await dotenv.load(fileName: '.env');
  await MapProvider.initialize();

  setupServiceLocator();

  await Modular.configure(
    appModule: AppModule(),
    initialRoute: '/',
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    debugLogEventBus: true,
  );

  runApp(const AppWidget());
}
