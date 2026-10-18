import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_state.dart';
import 'package:passenger/src/features/inbox/presentation/pages/inbox_page.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class MockInboxRepository extends Mock implements InboxRepository {}

class MockPassengerSessionStore extends Mock implements PassengerSessionStore {}

class MockInboxCubit extends MockCubit<InboxState> implements InboxCubit {}

void main() {
  testWidgets('shows notification skeleton while session is pending', (
    tester,
  ) async {
    final sessionBloc = MockSessionBloc();
    final inboxCubit = InboxCubit(inboxRepository: MockInboxRepository());
    final sessionStore = MockPassengerSessionStore();
    when(() => sessionBloc.state).thenReturn(const SessionLoading());
    addTearDown(inboxCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
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
    expect(
      find.byKey(const ValueKey<String>('inbox-loading-skeleton')),
      findsOneWidget,
    );
    expect(find.byWidgetPredicate((widget) => widget is Bone), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders AppErrorBanner when inbox cubit emits InboxErrorState', (
    tester,
  ) async {
    final sessionBloc = MockSessionBloc();
    final inboxCubit = MockInboxCubit();
    final sessionStore = MockPassengerSessionStore();
    when(() => sessionBloc.state)
        .thenReturn(const AuthenticatedSession(passengerId: 'user-1'));
    when(() => sessionStore.readPassengerId())
        .thenAnswer((_) async => 'user-1');
    when(() => inboxCubit.loadNotifications(any())).thenAnswer((_) async {});
    when(() => inboxCubit.state)
        .thenReturn(const InboxErrorState('Failed to load notifications.'));
    when(() => inboxCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
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

    expect(find.byType(AppErrorBanner), findsOneWidget);
    expect(find.text('Failed to load notifications.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
