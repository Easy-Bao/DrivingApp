import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/bloc/trip_history/trip_history_cubit.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/activity/view/driver_trip_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class _MockActivityRepository extends Mock
    implements IDriverActivityRepository {}

class _MockSessionService extends Mock implements SecureSessionService {}

void main() {
  testWidgets('shows a retryable error instead of an empty history state', (
    tester,
  ) async {
    final repository = _MockActivityRepository();
    final sessionService = _MockSessionService();
    when(
      () => sessionService.readDriverId(),
    ).thenAnswer((_) async => 'driver-1');
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
        theme: EasyRideTheme.light,
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
