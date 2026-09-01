import 'package:driver/src/app/theme/app_theme.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_cubit.dart';
import 'package:driver/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:driver/src/features/ride_history/presentation/view/driver_trip_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foundation/foundation.dart';

class _MockRideHistoryRepository extends Mock
    implements DriverRideHistoryRepository {}

class _MockSessionService extends Mock implements DriverSessionStore {}

void main() {
  testWidgets('shows a retryable error instead of an empty history state', (
    tester,
  ) async {
    final repository = _MockRideHistoryRepository();
    final sessionService = _MockSessionService();
    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-1');
    when(
      () => repository.fetchTripHistory('driver-1', limit: 25, offset: 0),
    ).thenAnswer(
      (_) async =>
          const Left(ServerFailure('backend query details must stay internal')),
    );

    final cubit = DriverTripHistoryCubit(
      repository: repository,
      sessionService: sessionService,
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: BlocProvider.value(
          value: cubit,
          child: const DriverTripHistoryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load trips'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('No trip history found'), findsNothing);
    expect(find.text('backend query details must stay internal'), findsNothing);
    expect(
      find.text(
        'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await cubit.close();
  });
}
