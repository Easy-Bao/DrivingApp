import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:passenger/src/features/profile/presentation/pages/account_page.dart';
import 'package:passenger/src/features/profile/presentation/widgets/profile_avatar.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

void main() {
  late MockProfileCubit profileCubit;
  late MockSessionBloc sessionBloc;

  setUp(() {
    profileCubit = MockProfileCubit();
    sessionBloc = MockSessionBloc();
    when(() => profileCubit.state).thenReturn(
      const ProfileState(
        name: 'Test Passenger',
        phone: '+639170000001',
        email: 'passenger@example.com',
      ),
    );
    when(() => sessionBloc.state)
        .thenReturn(const AuthenticatedSession(passengerId: 'passenger-1'));
  });

  Widget buildSubject({VoidCallback? onLogout}) {
    return MaterialApp(
      theme: AppTheme.main,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<SessionBloc>.value(value: sessionBloc),
        ],
        child: AccountPage(onLogout: onLogout),
      ),
    );
  }

  testWidgets('keeps the profile summary informational', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('Test Passenger'));
    await tester.tap(find.byType(ProfileAvatar));

    expect(find.text('Profile Info'), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.text('Safety Center'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not render cached identity after the session ends', (
    tester,
  ) async {
    when(() => sessionBloc.state).thenReturn(const GuestSession());

    await tester.pumpWidget(buildSubject(onLogout: () {}));

    expect(find.text('Test Passenger'), findsNothing);
    expect(find.text('Passenger'), findsOneWidget);
    expect(find.text('Add your mobile number'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('passenger-account-logout')),
      findsNothing,
    );
  });

  testWidgets('uses the fixed default surface and foreground contract', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final title = tester.widget<Text>(find.text('Account'));

    expect(scaffold.backgroundColor, isNull);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor,
      AppTheme.main.scaffoldBackgroundColor,
    );
    expect(title.style?.color, AppTheme.main.colorScheme.onSurface);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps only account destinations without redundant settings pages',
    (tester) async {
      var logoutCount = 0;
      await tester.pumpWidget(buildSubject(onLogout: () => logoutCount++));

      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Saved Places'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
      expect(find.text('PREFERENCES'), findsNothing);
      expect(find.text('Help Center'), findsNothing);
      expect(find.text('Terms of Service'), findsNothing);
      expect(find.text('About EasyRide'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('passenger-account-logout')),
        300,
      );
      await tester.tap(find.byKey(const ValueKey('passenger-account-logout')));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);
      expect(logoutCount, 0);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsNothing);
      expect(logoutCount, 0);

      await tester.tap(find.byKey(const ValueKey('passenger-account-logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(logoutCount, 1);
    },
  );

  testWidgets('keeps the bottom scroll clearance tight above the tab bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject(onLogout: () {}));

    final scrollView = find.byKey(
      const ValueKey<String>('passenger-account-scroll'),
    );
    await tester.drag(scrollView, const Offset(0, -1200));
    await tester.pump();

    final scrollRect = tester.getRect(scrollView);
    final logoutRect = tester.getRect(
      find.byKey(const ValueKey('passenger-account-logout')),
    );
    expect(scrollRect.bottom - logoutRect.bottom, lessThanOrEqualTo(90));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables OS touch splash and fits narrow large text viewports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ProfileCubit>.value(value: profileCubit),
            BlocProvider<SessionBloc>.value(value: sessionBloc),
          ],
          child: AccountPage(onLogout: () {}),
        ),
      ),
    );

    final detailsTile = tester.widget<InkWell>(
      find.byKey(
        const ValueKey<String>('passenger-account-item-Personal Details'),
      ),
    );
    expect(detailsTile.enableFeedback, isFalse);
    expect(detailsTile.splashFactory, NoSplash.splashFactory);
    expect(
      detailsTile.overlayColor?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(tester.takeException(), isNull);
  });
}
