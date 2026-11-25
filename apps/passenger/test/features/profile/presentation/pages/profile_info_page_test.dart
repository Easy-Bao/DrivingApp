import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:passenger/src/features/profile/presentation/pages/profile_info_page.dart';

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
        address: any(named: 'address'),
        gender: any(named: 'gender'),
        avatarPath: any(named: 'avatarPath'),
      ),
    ).thenAnswer((_) async => true);
  });

  Widget buildSubject({Future<XFile?> Function()? pickPhoto}) {
    return MaterialApp(
      theme: AppTheme.main,
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
    await tester.pump(const Duration(seconds: 4));

    verify(
      () => profileCubit.updateProfile(
        name: 'Updated Passenger',
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

  testWidgets('shows confirmation feedback when saving succeeds', (
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

    expect(find.text('Profile updated.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets(
    'fits narrow large-text viewports cleanly when unsaved actions appear',
    (tester) async {
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
            child: const ProfileInfoPage(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('passenger-profile-field-Full Name')),
        'Alex Rivera',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('passenger-profile-save')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('passenger-profile-discard')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
        pickPhoto: () async =>
            XFile.fromData(Uint8List(6 * 1024 * 1024), path: ''),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('passenger-profile-camera')),
    );
    await tester.pump();

    expect(
      find.text('Selected photo exceeds 5MB. Choose a smaller image.'),
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

  testWidgets('keeps email and phone fields read-only', (tester) async {
    await tester.pumpWidget(buildSubject());

    final phoneFinder = find.byKey(
      const ValueKey<String>('passenger-profile-phone-number'),
    );
    expect(phoneFinder, findsOneWidget);
    final phoneField = tester.widget<TextField>(phoneFinder);
    expect(phoneField.readOnly, isTrue);

    final emailFinder = find.byKey(
      const ValueKey<String>('passenger-profile-field-Email'),
    );
    expect(emailFinder, findsOneWidget);
    final emailField = tester.widget<TextField>(emailFinder);
    expect(emailField.readOnly, isTrue);
  });

  testWidgets(
    'separates editable profile fields from verified contact details cleanly',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('CONTACT'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(
        find.text('Email and phone changes require verification.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('passenger-profile-editable-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('passenger-profile-contact-card')),
        findsOneWidget,
      );
      expect(find.byType(AppSurfaceCard), findsNWidgets(2));
    },
  );

  testWidgets('updates hero name live and discards unsaved edits cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.enterText(
      find.byKey(const ValueKey<String>('passenger-profile-field-Full Name')),
      'Alex Rivera',
    );
    await tester.pump();

    expect(find.text('Alex Rivera'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('passenger-profile-discard')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('passenger-profile-discard')),
    );
    await tester.pump();

    expect(find.text('Test Passenger'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('passenger-profile-save')),
      findsNothing,
    );
  });

  testWidgets(
    'resolves full name from session rather than displaying email when profile name is an email',
    (tester) async {
      when(() => profileCubit.state).thenReturn(
        const ProfileState(
          name: 'passenger@example.com',
          phone: '+639170000001',
          email: 'passenger@example.com',
          gender: 'Female',
        ),
      );
      when(() => sessionBloc.state).thenReturn(
        const AuthenticatedSession(
          passengerId: 'passenger-1',
          passengerName: 'Jane Doe',
        ),
      );

      await tester.pumpWidget(buildSubject());

      final nameFinder = find.byKey(
        const ValueKey<String>('passenger-profile-field-Full Name'),
      );
      final textField = tester.widget<TextField>(nameFinder);
      expect(textField.controller?.text, 'Jane Doe');
      expect(find.text('Jane Doe'), findsNWidgets(2));
    },
  );

  testWidgets('disables OS touch splash and validates empty name inline', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    final cameraInkWell = tester.widget<InkWell>(
      find.byKey(const ValueKey<String>('passenger-profile-camera')),
    );
    expect(cameraInkWell.enableFeedback, isFalse);
    expect(cameraInkWell.splashFactory, NoSplash.splashFactory);

    await tester.enterText(
      find.byKey(const ValueKey<String>('passenger-profile-field-Full Name')),
      '   ',
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('passenger-profile-save')),
    );
    await tester.pump();

    expect(find.text('Enter your name.'), findsOneWidget);
    verifyNever(
      () => profileCubit.updateProfile(
        name: any(named: 'name'),
        address: any(named: 'address'),
        gender: any(named: 'gender'),
        avatarPath: any(named: 'avatarPath'),
      ),
    );
  });
}
