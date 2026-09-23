import 'package:driver/src/infrastructure/notifications/driver_incoming_request_alert.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DriverIncomingRequestAlert.channel, null);
  });

  test('uses the alarm alert channel for a new incoming request', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DriverIncomingRequestAlert.channel, (
          call,
        ) async {
          receivedCall = call;
          return null;
        });

    await DriverIncomingRequestAlert.play();

    expect(receivedCall?.method, 'playIncomingRideAlert');
  });
}
