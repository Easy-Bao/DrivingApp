import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/profile/view/driver_account_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late ModularTestScope scope;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'driver_name': 'Bao Driver',
      'driver_email': 'bao@example.com',
      'vehicle_type': 'Motorcycle',
      'plate_number': 'XYZ-123',
      'rating': '4.8',
    });
    final preferences = await SharedPreferences.getInstance();
    final storage = _MockSecureStorage();
    when(
      () => storage.read(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async => null);

    scope = ModularTestScope.fresh()
        .withInstance<SharedPreferences>(preferences)
        .withInstance<SecureSessionService>(
          SecureSessionService(storage: storage),
        );
    scope.setUp();
  });

  tearDown(() {
    scope.tearDown();
  });

  testWidgets('renders a compact driver account overview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.themeData, home: const DriverAccountPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bao Driver'), findsOneWidget);
    expect(find.text('bao@example.com'), findsOneWidget);
    expect(find.text('Motorcycle'), findsOneWidget);
    expect(find.text('XYZ-123'), findsOneWidget);
    expect(find.text('4.8 rating'), findsOneWidget);
    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('Account settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
