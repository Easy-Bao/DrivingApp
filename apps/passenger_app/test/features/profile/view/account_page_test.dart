import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/profile/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/view/account_page.dart';
import 'package:passenger_app/src/features/profile/view/widgets/profile_avatar_widget.dart';

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
        theme: AppTheme.themeData,
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
    expect(tester.takeException(), isNull);
  });
}
