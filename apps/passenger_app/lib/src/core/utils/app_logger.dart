import 'dart:developer' as dev;

class AppLogger {
  static void logInfo(String message) => dev.log(message, name: 'INFO');
  static void logError(String message, [Object? error]) => dev.log(message, name: 'ERROR', error: error);
}
