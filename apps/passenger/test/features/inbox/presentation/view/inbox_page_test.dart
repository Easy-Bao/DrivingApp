import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/app/theme/app_theme.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/view/inbox_page.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class MockInboxRepository extends Mock implements InboxRepository {}

class MockPassengerSessionStore extends Mock implements PassengerSessionStore {}

void main() {
  testWidgets('does not show notification skeleton while session is pending', (
    tester,
  ) async {
    final sessionBloc = MockSessionBloc();
    final inboxCubit = InboxCubit(inboxRepository: MockInboxRepository());
    final sessionStore = MockPassengerSessionStore();
    when(() => sessionBloc.state).thenReturn(const SessionLoading());
    addTearDown(inboxCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: sessionBloc),
            BlocProvider<InboxCubit>.value(value: inboxCubit),
          ],
          child: InboxPage(
            inboxCubit: inboxCubit,
            sessionService: sessionStore,
          ),
        ),
      ),
    );

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.byType(Bone), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
