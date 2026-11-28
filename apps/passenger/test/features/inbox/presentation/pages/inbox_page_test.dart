import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
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

class MockDismissibleInboxRepository extends Mock
    implements InboxRepository, DismissibleInboxRepository {}

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
          child: InboxPage(inboxCubit: cubit),
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
          child: InboxPage(inboxCubit: cubit),
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
            child: InboxPage(inboxCubit: cubit),
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
          child: InboxPage(inboxCubit: inboxCubit),
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
    when(() => sessionBloc.state)
        .thenReturn(const AuthenticatedSession(passengerId: 'user-1'));
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
          child: InboxPage(inboxCubit: inboxCubit),
        ),
      ),
    );

    expect(find.byType(AppErrorBanner), findsOneWidget);
    expect(find.text('Failed to load notifications.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'groups by date, filters categories, expands details, and deletes by id',
    (tester) async {
      final now = DateTime.now();
      final todayTimestamp = DateTime(now.year, now.month, now.day, 10, 15);
      final yesterdayTimestamp = todayTimestamp.subtract(
        const Duration(days: 1),
      );
      final earlierTimestamp = todayTimestamp.subtract(const Duration(days: 5));

      final session = MockSessionBloc();
      when(() => session.state)
          .thenReturn(const AuthenticatedSession(passengerId: 'p'));
      final repository = MockInboxRepository();
      when(() => repository.fetchPassengerNotifications('p')).thenAnswer(
        (_) async => Ok([
          InboxNotification(
            id: 'chat-1',
            title: 'New Message From Your Driver',
            message: 'I am waiting outside the main entrance.',
            timestamp: todayTimestamp,
            type: 'chat',
            isRead: false,
            roomId: 'room-1',
            userId: 'p',
            peerId: 'driver-1',
            peerName: 'Alex',
          ),
          InboxNotification(
            id: 'ride-1',
            title: 'Ride completed',
            message: 'Your receipt for ₱245.00 is ready.',
            timestamp: yesterdayTimestamp,
            type: 'ride',
            isRead: false,
          ),
          InboxNotification(
            id: 'ride-2',
            title: 'Previous trip receipt',
            message: 'Thank you for riding with EasyRide.',
            timestamp: earlierTimestamp,
            type: 'ride',
            isRead: true,
          ),
        ]),
      );
      final cubit = InboxCubit(inboxRepository: repository);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: BlocProvider<SessionBloc>.value(
            value: session,
            child: InboxPage(inboxCubit: cubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('EARLIER'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('inbox-filter-rides')),
      );
      await tester.pumpAndSettle();
      expect(find.text('New Message From Your Driver'), findsNothing);
      expect(find.text('Ride completed'), findsOneWidget);
      expect(find.text('Previous trip receipt'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('inbox-notification-ride-1')),
      );
      await tester.pumpAndSettle();

      expect(
        (cubit.state as InboxLoadedState).notifications
            .singleWhere((n) => n.id == 'ride-1')
            .isRead,
        isTrue,
      );
      final deleteButton = find.byKey(
        const ValueKey<String>('inbox-delete-ride-1'),
      );
      expect(deleteButton, findsOneWidget);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect((cubit.state as InboxLoadedState).notifications.map((n) => n.id), [
        'chat-1',
        'ride-2',
      ]);

      await tester.tap(
        find.byKey(const ValueKey<String>('inbox-filter-unread')),
      );
      await tester.pumpAndSettle();
      expect(find.text('New Message From Your Driver'), findsOneWidget);
      expect(find.text('Previous trip receipt'), findsNothing);

      await tester.drag(
        find.byKey(const ValueKey<String>('inbox-dismissible-chat-1')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('All caught up'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('inbox-reset-filter')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Previous trip receipt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps expanded unread notification visible while reading', (
    tester,
  ) async {
    final session = MockSessionBloc();
    when(() => session.state)
        .thenReturn(const AuthenticatedSession(passengerId: 'p'));
    final repository = MockInboxRepository();
    when(() => repository.fetchPassengerNotifications('p')).thenAnswer(
      (_) async => Ok([
        InboxNotification(
          id: 'ride-unread',
          title: 'Ride receipt',
          message: 'Detailed fare breakdown is now available in your inbox.',
          timestamp: DateTime.now(),
          type: 'ride',
          isRead: false,
        ),
      ]),
    );
    final cubit = InboxCubit(inboxRepository: repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider<SessionBloc>.value(
          value: session,
          child: InboxPage(inboxCubit: cubit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('inbox-filter-unread')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('inbox-notification-ride-unread')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('inbox-delete-ride-unread')),
      findsOneWidget,
    );
    expect(
      (cubit.state as InboxLoadedState).notifications.single.isRead,
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('inbox-notification-ride-unread')),
    );
    await tester.pumpAndSettle();

    expect(find.text('All caught up'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports pull-to-refresh for authenticated inbox', (
    tester,
  ) async {
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
          timestamp: DateTime.now(),
          type: 'ride',
          isRead: true,
        ),
      ]),
    );
    final cubit = InboxCubit(inboxRepository: repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider<SessionBloc>.value(
          value: session,
          child: InboxPage(inboxCubit: cubit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 320),
      800,
    );
    await tester.pumpAndSettle();

    verify(() => repository.fetchPassengerNotifications('p')).called(2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'filter tabs glide indicator smoothly and disable OS touch splash',
    (tester) async {
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
            timestamp: DateTime.now(),
            type: 'ride',
            isRead: false,
          ),
        ]),
      );
      final cubit = InboxCubit(inboxRepository: repository);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: BlocProvider<SessionBloc>.value(
            value: session,
            child: InboxPage(inboxCubit: cubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final unreadTabFinder = find.byKey(
        const ValueKey<String>('inbox-filter-unread'),
      );
      final unreadTab = tester.widget<InkWell>(unreadTabFinder);
      expect(unreadTab.enableFeedback, isFalse);
      expect(unreadTab.splashFactory, NoSplash.splashFactory);
      expect(
        unreadTab.overlayColor?.resolve({WidgetState.pressed}),
        Colors.transparent,
      );
      expect(
        unreadTab.overlayColor?.resolve({WidgetState.hovered}),
        Colors.transparent,
      );

      final notificationInkWell = tester.widget<InkWell>(
        find.byKey(const ValueKey<String>('inbox-notification-1')),
      );
      expect(notificationInkWell.enableFeedback, isFalse);
      expect(notificationInkWell.splashFactory, NoSplash.splashFactory);
      expect(
        notificationInkWell.overlayColor?.resolve({WidgetState.pressed}),
        Colors.transparent,
      );

      final indicatorFinder = find.byKey(
        const ValueKey<String>('inbox-filter-indicator'),
      );
      expect(indicatorFinder, findsOneWidget);
      final initialLeft = tester.getTopLeft(indicatorFinder).dx;

      await tester.tap(unreadTabFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final midLeft = tester.getTopLeft(indicatorFinder).dx;

      await tester.pumpAndSettle();
      final finalLeft = tester.getTopLeft(indicatorFinder).dx;

      expect(midLeft, greaterThan(initialLeft));
      expect(finalLeft, greaterThan(midLeft));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows undo snackbar when deleting a notification and restores it on Undo',
    (tester) async {
      final session = MockSessionBloc();
      when(() => session.state)
          .thenReturn(const AuthenticatedSession(passengerId: 'p'));
      final repository = MockDismissibleInboxRepository();
      when(() => repository.fetchPassengerNotifications('p')).thenAnswer(
        (_) async => Ok([
          InboxNotification(
            id: '77',
            title: 'Ride completed',
            message: 'Receipt ready',
            timestamp: DateTime.now(),
            type: 'ride',
            isRead: false,
          ),
        ]),
      );
      when(() => repository.deletePassengerNotification('p', '77'))
          .thenAnswer((_) async => const Ok(null));

      final cubit = InboxCubit(inboxRepository: repository);
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: BlocProvider<SessionBloc>.value(
            value: session,
            child: InboxPage(inboxCubit: cubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey<String>('inbox-dismissible-77')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification deleted.'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect((cubit.state as InboxLoadedState).notifications, isEmpty);
      verifyNever(() => repository.deletePassengerNotification('p', '77'));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Ride completed'), findsOneWidget);
      expect((cubit.state as InboxLoadedState).notifications.map((n) => n.id), [
        '77',
      ]);
      verifyNever(() => repository.deletePassengerNotification('p', '77'));
    },
  );
}
