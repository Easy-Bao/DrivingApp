import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/app/theme/app_theme.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile/profile_cubit.dart';
import 'package:passenger/src/features/profile/presentation/view/account_page.dart';
import 'package:passenger/src/features/profile/presentation/widgets/profile_avatar_widget.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

void main() {
  late MockProfileCubit profileCubit;

  setUp(() {
    profileCubit = MockProfileCubit();
    when(() => profileCubit.state).thenReturn(
      const ProfileState(
        name: 'Test Passenger',
        phone: '+639170000001',
        email: 'passenger@example.com',
      ),
    );
  });

  testWidgets('opens profile info from both the name and avatar', (
    tester,
  ) async {
    var profileTapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: BlocProvider<ProfileCubit>.value(
          value: profileCubit,
          child: AccountPage(onProfileTap: () => profileTapCount++),
        ),
      ),
    );

    await tester.tap(find.text('Test Passenger'));
    await tester.tap(find.byType(ProfileAvatarWidget));

    expect(profileTapCount, 2);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.text('Safety Center'), findsNothing);
    expect(find.text('Location access and app support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the fixed default surface and foreground contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: BlocProvider<ProfileCubit>.value(
          value: profileCubit,
          child: const AccountPage(),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final title = tester.widget<Text>(find.text('Account'));

    expect(scaffold.backgroundColor, AppTheme.data.scaffoldBackgroundColor);
    expect(title.style?.color, AppTheme.data.colorScheme.onSurface);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes real account, legal, and logout destinations', (
    tester,
  ) async {
    var logoutCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: BlocProvider<ProfileCubit>.value(
          value: profileCubit,
          child: AccountPage(onLogout: () => logoutCount++),
        ),
      ),
    );

    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('About BaoRide'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('passenger-account-logout')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('passenger-account-logout')));
    expect(logoutCount, 1);
  });
}
