import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/profile/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/view/profile_info_page.dart';
import 'package:shared_ui/shared_ui.dart';

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
        address: 'Legacy fixed address',
        gender: 'Female',
      ),
    );
    when(
      () => sessionBloc.state,
    ).thenReturn(const AuthenticatedSession(passengerId: 'passenger-1'));
    when(
      () => profileCubit.updateProfile(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        email: any(named: 'email'),
        address: any(named: 'address'),
        gender: any(named: 'gender'),
        avatarPath: any(named: 'avatarPath'),
      ),
    ).thenAnswer((_) async => true);
  });

  Widget buildSubject({Future<XFile?> Function()? pickPhoto}) {
    return MaterialApp(
      theme: EasyRideTheme.light,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<SessionBloc>.value(value: sessionBloc),
        ],
        child: ProfileInfoPage(pickPhoto: pickPhoto),
      ),
    );
  }

  testWidgets('is editable immediately and reveals Save only after a change', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Edit'), findsNothing);
    expect(find.text('Address'), findsNothing);
    expect(find.text('+63'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('passenger-profile-save')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('passenger-profile-field-Full Name')),
      'Updated Passenger',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('passenger-profile-save')),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('saves the edited profile and keeps logout in profile info', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(
      find.byKey(const ValueKey<String>('passenger-profile-field-Full Name')),
      'Updated Passenger',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('passenger-profile-save')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    verify(
      () => profileCubit.updateProfile(
        name: 'Updated Passenger',
        phone: '+639170000001',
        email: 'passenger@example.com',
        address: 'Legacy fixed address',
        gender: 'Female',
        avatarPath: '',
      ),
    ).called(1);

    final logoutButton = find.byKey(
      const ValueKey<String>('passenger-profile-logout'),
    );
    await tester.scrollUntilVisible(
      logoutButton,
      420,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(logoutButton);
    await tester.pump();
    verify(() => sessionBloc.add(const SessionLogoutRequested())).called(1);
  });

  testWidgets('camera action adds a photo draft and reveals Save', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(pickPhoto: () async => XFile('/tmp/passenger-profile.png')),
    );

    expect(
      find.byKey(const ValueKey<String>('passenger-profile-camera')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('passenger-profile-camera')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('passenger-profile-save')),
      findsOneWidget,
    );
  });
}
