import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile/profile_cubit.dart';
import 'package:passenger/src/features/profile/presentation/view/profile_info_page.dart';

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
    when(() => sessionBloc.state)
        .thenReturn(const AuthenticatedSession(passengerId: 'passenger-1'));
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
      theme: EasyRideTheme.main,
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

  testWidgets('saves the edited profile without a logout action', (
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

    expect(
      find.byKey(const ValueKey<String>('passenger-profile-logout')),
      findsNothing,
    );
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

  testWidgets('rejects photo uploads exceeding 5MB', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        pickPhoto: () async => XFile.fromData(
          Uint8List(6 * 1024 * 1024),
          path: '',
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('passenger-profile-camera')),
    );
    await tester.pump();

    expect(
      find.text('Selected photo exceeds 5MB limit. Please choose a smaller image.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('passenger-profile-save')),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('keeps the redesigned profile form inside a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());

    expect(find.text('Personal details'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('passenger-profile-info-scroll')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters non-numeric characters from phone number input', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    final phoneFinder = find.byKey(
      const ValueKey<String>('passenger-profile-phone-number'),
    );
    expect(phoneFinder, findsOneWidget);

    await tester.enterText(phoneFinder, '');
    await tester.enterText(phoneFinder, '+1 (555) 123-4567');
    await tester.pump();

    final textField = tester.widget<TextField>(phoneFinder);
    expect(textField.controller?.text, '15551234567');
  });
}
