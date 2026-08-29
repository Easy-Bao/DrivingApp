import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/profile/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/view/account_page.dart';
import 'package:passenger_app/src/features/profile/view/widgets/profile_avatar_widget.dart';
import 'package:shared_ui/shared_ui.dart';

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
        theme: EasyRideTheme.light,
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
    expect(find.text('Appearance and app behavior'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses semantic surfaces and foregrounds in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        darkTheme: EasyRideTheme.dark,
        themeMode: ThemeMode.dark,
        home: BlocProvider<ProfileCubit>.value(
          value: profileCubit,
          child: const AccountPage(),
        ),
      ),
    );

    final darkScheme = EasyRideTheme.dark.colorScheme;
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final title = tester.widget<Text>(find.text('Account'));

    expect(
      scaffold.backgroundColor,
      EasyRideTheme.dark.scaffoldBackgroundColor,
    );
    expect(title.style?.color, darkScheme.onSurface);
    expect(tester.takeException(), isNull);
  });
}
