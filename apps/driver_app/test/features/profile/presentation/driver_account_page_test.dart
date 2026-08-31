import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/presentation/driver_account_page.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router_modular/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockDriverProfileRepository extends Mock
    implements IDriverProfileRepository {}

Future<void> _noopLogout() async {}

void main() {
  late ModularTestScope scope;
  late _MockDriverProfileRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'driver_name': 'Bao Driver',
      'driver_phone': '+639170000001',
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
        phone: '+639170000001',
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

  testWidgets('matches the passenger account layout with driver details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: BlocProvider(
          create: (_) => DriverAccountCubit(repository: repository)..load(),
          child: const DriverAccountPage(onLogout: _noopLogout),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bao Driver'), findsOneWidget);
    expect(find.text('+639170000001'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Driver Details'), findsOneWidget);
    expect(find.textContaining('Motorcycle'), findsOneWidget);
    expect(find.textContaining('XYZ-123'), findsOneWidget);
    expect(find.text('Ratings, trips, and earnings'), findsOneWidget);
    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Location access and app support'), findsOneWidget);
    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('About BaoRide'), findsOneWidget);
    expect(find.text('Account Settings'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('driver-profile-avatar'))),
      const Size(76, 76),
    );
    expect(find.byTooltip('Refresh account'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the fixed light account surface contract', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: BlocProvider(
          create: (_) => DriverAccountCubit(repository: repository)..load(),
          child: const DriverAccountPage(onLogout: _noopLogout),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final title = tester.widget<Text>(find.text('Account'));

    expect(
      scaffold.backgroundColor,
      EasyRideTheme.light.scaffoldBackgroundColor,
    );
    expect(title.style?.color, EasyRideTheme.light.colorScheme.onSurface);
    expect(tester.takeException(), isNull);
  });
}
