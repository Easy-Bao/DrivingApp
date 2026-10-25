import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_state.dart';
import 'package:passenger/src/features/inbox/presentation/pages/inbox_page.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class MockInboxRepository extends Mock implements InboxRepository {}

class MockSessionStore extends Mock implements SessionStore {}

class MockInboxCubit extends MockCubit<InboxState> implements InboxCubit {}

void main() {
  testWidgets('guest guidance fits large text without account actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = MockSessionBloc();
    when(() => session.state).thenReturn(const GuestSession());
    final repository = MockInboxRepository();
    final cubit = InboxCubit(inboxRepository: repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: BlocProvider<SessionBloc>.value(
          value: session,
          child: InboxPage(
            inboxCubit: cubit,
            sessionService: MockSessionStore(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stay up to date'), findsOneWidget);
    expect(
      find.text(
        'Sign in or create an account to receive ride updates and account notifications.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mark all as read'), findsNothing);
    verifyNever(() => repository.fetchPassengerNotifications(any()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk read action shows progress and disables after success', (
    tester,
  ) async {
    final session = MockSessionBloc();
    when(() => session.state)
        .thenReturn(const AuthenticatedSession(passengerId: 'p'));
    final repository = MockInboxRepository();
    final response = Completer<Result<void, Failure>>();
    when(() => repository.fetchPassengerNotifications('p')).thenAnswer(
      (_) async => Ok([
        InboxNotification(
          id: '1',
          title: 'Ride completed',
          message: 'Receipt ready',
          timestamp: DateTime(2026),
          type: 'ride',
          isRead: false,
        ),
      ]),
    );
    when(() => repository.markAllPassengerNotificationsAsRead('p'))
        .thenAnswer((_) => response.future);
    final cubit = InboxCubit(inboxRepository: repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider<SessionBloc>.value(
          value: session,
          child: InboxPage(
            inboxCubit: cubit,
            sessionService: MockSessionStore(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Mark all as read')).dy,
      lessThan(tester.getBottomLeft(find.text('Inbox')).dy),
      reason: 'bulk action belongs beside the heading',
    );
    await tester.tap(find.text('Mark all as read'));
    await tester.pump();
    expect(find.text('Marking…'), findsOneWidget);
    response.complete(const Ok(null));
    await tester.pumpAndSettle();
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Mark all as read'),
    );
    expect(button.onPressed, isNull);
    verify(() => repository.markAllPassengerNotificationsAsRead('p')).called(1);
  });

  testWidgets(
    'bulk read failure stays contextual and retry works at narrow large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = MockSessionBloc();
      when(() => session.state)
          .thenReturn(const AuthenticatedSession(passengerId: 'p'));
      final repository = MockInboxRepository();
      when(() => repository.fetchPassengerNotifications('p')).thenAnswer(
        (_) async => Ok([
          InboxNotification(
            id: '1',
            title: 'Ride completed',
            message: 'Receipt ready',
            timestamp: DateTime(2026),
            type: 'ride',
            isRead: false,
          ),
        ]),
      );
      when(
        () => repository.markAllPassengerNotificationsAsRead('p'),
      ).thenAnswer(
        (_) async =>
            const Err(ServerFailure.withStatusCode('Method not allowed', 405)),
      );
      final cubit = InboxCubit(inboxRepository: repository);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: BlocProvider<SessionBloc>.value(
            value: session,
            child: InboxPage(
              inboxCubit: cubit,
              sessionService: MockSessionStore(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Mark all as read')).dy,
        greaterThan(
          tester.getBottomLeft(find.text('Messages and receipts')).dy,
        ),
      );
      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();
      expect(
        find.text('Couldn’t mark notifications as read. Try again.'),
        findsOneWidget,
      );
      expect(
        (cubit.state as InboxLoadedState).notifications.single.isRead,
        isFalse,
      );
      when(() => repository.markAllPassengerNotificationsAsRead('p'))
          .thenAnswer((_) async => const Ok(null));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorBanner), findsNothing);
      expect(
        (cubit.state as InboxLoadedState).notifications.single.isRead,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows notification skeleton while session is pending', (
    tester,
  ) async {
    final sessionBloc = MockSessionBloc();
    final inboxCubit = InboxCubit(inboxRepository: MockInboxRepository());
    final sessionStore = MockSessionStore();
    when(() => sessionBloc.state).thenReturn(const SessionLoading());
    addTearDown(inboxCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
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
    final sessionStore = MockSessionStore();
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
        theme: AppTheme.main,
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
