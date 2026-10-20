import 'dart:async';

import 'package:driver/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/trip_history_cubit.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockRideHistoryRepository extends Mock
    implements RideHistoryRepository {}

class _MockSessionService extends Mock implements SessionStore {}

typedef _Page = Result<OffsetPage<Map<String, dynamic>>, Failure>;

void main() {
  test('refresh supersedes an in-flight pagination response', () async {
    final repository = _MockRideHistoryRepository();
    final sessionService = _MockSessionService();
    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-1');
    final firstPages = [
      const OffsetPage<Map<String, dynamic>>(
        items: [
          {'id': 1},
        ],
        hasMore: true,
        nextOffset: 25,
      ),
      const OffsetPage<Map<String, dynamic>>(
        items: [
          {'id': 2},
        ],
        hasMore: true,
        nextOffset: 25,
      ),
    ];
    var firstPageCalls = 0;
    when(() => repository.fetchTripHistory('driver-1', limit: 25, offset: 0))
        .thenAnswer((_) async => Ok(firstPages[firstPageCalls++]));
    final stalePage = Completer<_Page>();
    when(() => repository.fetchTripHistory('driver-1', limit: 25, offset: 25))
        .thenAnswer((_) => stalePage.future);

    final cubit = TripHistoryCubit(
      repository: repository,
      sessionService: sessionService,
    );
    await cubit.load();
    final pagination = cubit.loadMore();
    await Future<void>.delayed(Duration.zero);
    await cubit.load();

    stalePage.complete(
      const Ok(
        OffsetPage<Map<String, dynamic>>(
          items: [
            {'id': 99},
          ],
          hasMore: false,
          nextOffset: null,
        ),
      ),
    );
    await pagination;

    expect(cubit.state.trips.map((trip) => trip['id']), [2]);
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.nextOffset, 25);
    expect(cubit.state.isLoadingMore, isFalse);

    await cubit.close();
  });
}
