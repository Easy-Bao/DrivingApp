import 'package:BaoRide/app_module.dart';
import 'package:BaoRide/app_widget.dart';
import 'package:BaoRide/core/services/map_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:BaoRide/src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();
  await dotenv.load(fileName: ".env");
  await MapProvider.initialize();

  await Modular.configure(
    appModule: AppModule(),
    initialRoute: "/",
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    debugLogEventBus: true,
  );

  runApp(const AppWidget());
}

//TODO: Make feedback message or flow if driver is there, but not responding to the request. Maybe a timeout of 30 seconds, and then show a message to the user that the driver is not responding, and ask if they want to try again or cancel the request.
//TODO: Make a flow if you are currently go to your destination as a passenger when driver set that complete passenger automatically get out of the car and show a message that you have arrived at your destination, and ask if you want to rate the driver or not. If you want to rate the driver, show a rating screen with a text field for feedback and a submit button. If you don't want to rate the driver, just show a message that you have arrived at your destination and thank you for using BaoRide.
