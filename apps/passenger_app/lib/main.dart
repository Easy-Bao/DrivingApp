import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/app_module.dart';
import 'package:passenger_app/app_widget.dart';
import 'package:passenger_app/core/di/service_locator.dart';
import 'package:passenger_app/core/services/map_provider.dart';
import 'package:passenger_app/src/rust/frb_generated.dart';

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
