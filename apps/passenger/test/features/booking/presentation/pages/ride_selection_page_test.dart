import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/testing.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:maps/maps.dart' as maps;
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/domain/entities/fare_estimate.dart';
import 'package:passenger/src/features/booking/domain/repositories/fare_repository.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/booking/presentation/pages/ride_selection_page.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile_cubit.dart';

class _BookingBloc extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

class _SessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class _ProfileCubit extends MockCubit<ProfileState> implements ProfileCubit {}

class _FareRepository extends Mock implements FareRepository {}

class _LocationRepository extends Mock implements maps.LocationRepository {}

void main() {
  setUpAll(() => registerFallbackValue(const CancelBookingEvent()));

  testWidgets('opens nearby-driver selection without sending a ride request', (
    tester,
  ) async {
    const destination = maps.Place(
      id: 'dropoff',
      name: 'Charleston Park',
      fullAddress: 'Charleston Park',
      latitude: 37.42,
      longitude: -122.08,
    );
    const fare = FareEstimate(
      baseFare: 20,
      distanceCharge: 5,
      timeCharge: 3.6,
      surgeCharge: 0,
      totalFare: 28.6,
    );
    final booking = _BookingBloc();
    final session = _SessionBloc();
    final profile = _ProfileCubit();
    final fares = _FareRepository();
    final locations = _LocationRepository();
    final drafts = BookingDraftCubit();
    addTearDown(drafts.close);
    when(() => booking.state).thenReturn(const BookingInitial());
    when(() => booking.hasActiveBooking).thenReturn(false);
    when(() => booking.hasActiveDriverSearch).thenReturn(false);
    when(() => session.state)
        .thenReturn(const AuthenticatedSession(passengerId: '1'));
    when(() => profile.state).thenReturn(const ProfileState());
    when(() => profile.loadProfile(refreshRemote: any(named: 'refreshRemote')))
        .thenAnswer((_) async {});
    when(() => locations.getRoute(body: any(named: 'body'))).thenAnswer(
      (_) async => const maps.Route(
        polylinePoints: [],
        distanceKm: 1.234,
        durationSeconds: 321,
      ),
    );
    when(
      () => fares.estimateFare(
        distanceKm: any(named: 'distanceKm'),
        durationMinutes: any(named: 'durationMinutes'),
        originLatitude: any(named: 'originLatitude'),
        originLongitude: any(named: 'originLongitude'),
        destinationLatitude: any(named: 'destinationLatitude'),
        destinationLongitude: any(named: 'destinationLongitude'),
      ),
    ).thenAnswer((_) async => const Ok(fare));
    MapboxMapsFlutterPlatform.instance = _MapPlatform();
    final scope = ModularTestScope.fresh().withInstance(
      AppLifecycleCoordinator(),
    );
    scope.setUp();
    addTearDown(() async {
      await scope.get<AppLifecycleCoordinator>().dispose();
      scope.tearDown();
    });
    await maps.MapProvider.initialize(
      nativeService: maps.MapNativeService(
        placeServiceBaseUri: Uri.parse('http://test.local'),
        apiClient: locations,
      ),
    );
    maps.MapProvider.clearLookupCaches();
    final submitted = <BookingEvent>[];
    when(() => booking.add(any())).thenAnswer(
      (invocation) =>
          submitted.add(invocation.positionalArguments.single as BookingEvent),
    );
    Map<String, dynamic>? searchPayload;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<BookingBloc>.value(value: booking),
              BlocProvider<SessionBloc>.value(value: session),
              BlocProvider<ProfileCubit>.value(value: profile),
              BlocProvider<BookingDraftCubit>.value(value: drafts),
            ],
            child: RideSelectionPage(
              destination: destination,
              fareRepository: fares,
              pickupLatitude: 37.4,
              pickupLongitude: -122.1,
              pickupAddress: 'Mountain View',
              initialTipAmount: 10,
              initialNotes: 'Near the entrance',
            ),
          ),
        ),
        GoRoute(
          path: '/search',
          name: BookingRoutes.findingDriver,
          builder: (_, state) {
            searchPayload = Map<String, dynamic>.from(state.extra! as Map);
            expect(submitted.whereType<StartOpenBookingEvent>(), isEmpty);
            return const Scaffold(body: Text('Driver search'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.main, routerConfig: router),
    );
    await tester.pumpAndSettle();
    final book = find.byKey(const ValueKey('book-directly-button'));
    await tester.tap(book);
    await tester.tap(book);
    await tester.pumpAndSettle();
    expect(submitted.whereType<StartOpenBookingEvent>(), isEmpty);
    expect(submitted.whereType<StartDirectBookingEvent>(), isEmpty);
    expect(searchPayload!['fare'], closeTo(38.6, 0.001));
    expect(searchPayload!['passengerNote'], 'Near the entrance');
    expect(searchPayload!['pickupLat'], 37.4);
    expect(searchPayload!['pickupLng'], -122.1);
    expect(searchPayload!['distanceKm'], 1.234);
    expect(searchPayload!['durationMinutes'], 321 / 60);
    expect(find.text('Driver search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _MapPlatform extends MapboxMapsFlutterPlatform {
  @override
  Widget buildView({
    required String styleUri,
    PlatformMapCreatedCallback? onMapCreated,
    ViewportState? viewport,
    ViewportTransition? viewportTransition,
    void Function(bool)? viewportTransitionCompletion,
    void Function(MapEvent)? onMapEvent,
    MapOptions? mapOptions,
    bool? textureView,
    // ignore: experimental_member_use
    required AndroidPlatformViewHostingMode androidHostingMode,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    bool? isOpaque = true,
  }) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => onMapEvent?.call(
        MapLoadedEventData(
          timeInterval: EventTimeInterval(
            begin: DateTime.utc(2026),
            end: DateTime.utc(2026),
          ),
        ),
      ),
    );
    return const SizedBox.expand();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
