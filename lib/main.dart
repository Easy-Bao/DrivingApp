import 'package:BaoRide/app_module.dart';
import 'package:BaoRide/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Modular.configure(
    appModule: AppModule(),
    initialRoute: "/",
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    debugLogEventBus: true,
  );

  runApp(const AppWidget());
}
