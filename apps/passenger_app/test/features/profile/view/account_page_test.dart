import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/profile/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/view/account_page.dart';

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
    when(
      () => sessionBloc.state,
    ).thenReturn(const AuthenticatedSession(passengerId: 'passenger-1'));
  });

  testWidgets('requests app-wide session logout from the account page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<SessionBloc>.value(value: sessionBloc),
        ],
        child: const MaterialApp(home: AccountPage()),
      ),
    );

    await tester.ensureVisible(find.text('Log Out'));
    await tester.tap(find.text('Log Out'));
    await tester.pump();

    verify(() => sessionBloc.add(const SessionLogoutRequested())).called(1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
