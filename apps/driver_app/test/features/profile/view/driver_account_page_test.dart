import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/profile/view/driver_account_page.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router_modular/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockDriverProfileRepository extends Mock
    implements IDriverProfileRepository {}

void main() {
  late ModularTestScope scope;
  late _MockDriverProfileRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'driver_name': 'Bao Driver',
      'driver_email': 'bao@example.com',
      'vehicle_type': 'Motorcycle',
      'plate_number': 'XYZ-123',
      'rating': '4.8',
    });
    final preferences = await SharedPreferences.getInstance();
    repository = _MockDriverProfileRepository();
    when(() => repository.getCachedAccount()).thenReturn(
      const DriverAccountSnapshot(
        name: 'Bao Driver',
        email: 'bao@example.com',
        vehicleType: 'Motorcycle',
        plateNumber: 'XYZ-123',
        ratingLabel: '4.8',
      ),
    );
    when(() => repository.refreshAccount()).thenAnswer(
      (_) async => const Left(
        NetworkFailure('Account refresh is unavailable in this widget test.'),
      ),
    );
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
      MaterialApp(
        theme: AppTheme.themeData,
        home: DriverAccountPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bao Driver'), findsOneWidget);
    expect(find.text('bao@example.com'), findsOneWidget);
    expect(find.text('Motorcycle'), findsOneWidget);
    expect(find.text('XYZ-123'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.byTooltip('Refresh account'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
