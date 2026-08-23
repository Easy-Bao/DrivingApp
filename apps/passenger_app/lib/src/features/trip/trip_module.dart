import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/services/background_telemetry_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/driver_profile/data/datasources/driver_profile_remote_data_source.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip/data/datasources/booking_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/datasources/driver_discovery_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/datasources/fare_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/datasources/ride_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/repositories/driver_repository.dart';
import 'package:passenger_app/src/features/trip/data/repositories/track_repository.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:passenger_app/src/features/trip/view/activity_detail_map_page.dart';
import 'package:passenger_app/src/features/trip/view/driver_matched_page.dart';
import 'package:passenger_app/src/features/trip/view/finding_driver_page.dart';
import 'package:passenger_app/src/features/trip/view/map_pin_page.dart';
import 'package:passenger_app/src/features/trip/view/ride_selection_page.dart';
import 'package:passenger_app/src/features/trip/view/search_destination_page.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class TripModule {
  TripModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<BookingRemoteDataSource>(
        (i) => BookingRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DriverDiscoveryRemoteDataSource>(
        (i) => DriverDiscoveryRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<FareRemoteDataSource>(
        (i) => FareRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<RideRemoteDataSource>(
        (i) => RideRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<IDriverRepository>(
        (i) => DriverRepository(
          discoveryDataSource: i.get<DriverDiscoveryRemoteDataSource>(),
          locationApiClient: i.get<ILocationApiClient>(),
        ),
      )
      ..addLazySingleton<ITrackRepository>(
        (i) => TrackRepository(remoteDataSource: i.get<RideRemoteDataSource>()),
      )
      ..addLazySingleton<BookingBloc>(
        (i) => BookingBloc(
          driverRepository: i.get<IDriverRepository>(),
          bookingDataSource: i.get<BookingRemoteDataSource>(),
          driverProfileDataSource: i.get<DriverProfileRemoteDataSource>(),
          secureSessionService: i.get<SecureSessionService>(),
          inboxCubit: i.get<InboxCubit>(),
          backgroundTelemetryService: i.get<BackgroundTelemetryService>(),
          realtimeClient: i.get<RealtimeWebSocketClient>(),
        ),
      )
      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(rideDataSource: i.get<RideRemoteDataSource>()),
      )
      ..addFactory<TrackDriverCubit>(
        (i) => TrackDriverCubit(
          repository: i.get<ITrackRepository>(),
          sessionService: i.get<SecureSessionService>(),
          backgroundTelemetryService: i.get<BackgroundTelemetryService>(),
        ),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: TripRoutes.searchDestination,
      TripRoutes.searchDestinationPath,
      child: (context, GoRouterState state) => SearchDestinationPage(
        preselectedRideType: state.uri.queryParameters['rideType'],
        pickupAddress: state.uri.queryParameters['pickupAddress'],
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.activityDetailMap,
      TripRoutes.activityDetailMapPath,
      child: (context, GoRouterState state) {
        final data = RoutePayload.from(
          extra: state.extra,
          queryParameters: state.uri.queryParameters,
        );
        final latitude = data.doubleValue('lat');
        final longitude = data.doubleValue('lng');
        if (latitude == null || longitude == null) {
          return const Scaffold(
            body: Center(child: Text('Location data is unavailable.')),
          );
        }
        return ActivityDetailMapPage(
          placeName: data.string('title') ?? 'Location',
          placeSubtitle: data.string('subtitle') ?? '',
          destinationLat: latitude,
          destinationLng: longitude,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.mapPin,
      TripRoutes.mapPinPath,
      child: (context, GoRouterState state) => const MapPinPage(),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.rideSelection,
      TripRoutes.rideSelectionPath,
      child: (context, GoRouterState state) {
        final extra = state.extra;
        final data = RoutePayload.from(
          extra: extra,
          queryParameters: state.uri.queryParameters,
        );
        final destination = extra is PlaceModel
            ? extra
            : data.object<PlaceModel>('destination') ??
                  _destinationFromQuery(data);
        final distanceKm = data.doubleValue('distanceKm');
        final distance = data.string('distance');
        final duration = data.string('duration');
        if (destination == null) {
          return const Scaffold(
            body: Center(child: Text('Trip route data is unavailable.')),
          );
        }
        return BlocProvider<BookingBloc>.value(
          value: Modular.get<BookingBloc>(),
          child: RideSelectionPage(
            destination: destination,
            distance: distance,
            duration: duration,
            distanceKm: distanceKm,
            rideType: data.string('rideType') ?? 'solo',
            initialTipAmount: data.intValue('tipAmount') ?? 0,
            initialNotes: data.string('notes') ?? '',
            pickupLatitude: data.doubleValue('pickupLat'),
            pickupLongitude: data.doubleValue('pickupLng'),
            pickupAddress: data.string('pickupAddress'),
          ),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.findingDriver,
      TripRoutes.findingDriverPath,
      child: (context, GoRouterState state) {
        final data = RoutePayload.from(extra: state.extra);
        final destination = data.object<PlaceModel>('destination');
        if (destination == null) {
          return const Scaffold(
            body: Center(child: Text('Destination data is unavailable.')),
          );
        }
        final fare = data.doubleValue('fare');
        final distance = data.string('distance');
        final duration = data.string('duration');
        if (fare == null || fare <= 0 || distance == null || duration == null) {
          return const Scaffold(
            body: Center(child: Text('Fare and trip data are unavailable.')),
          );
        }
        return FindingDriverPage(
          rideType: data.string('rideType') ?? 'Solo Ride',
          fare: fare,
          destination: destination,
          distance: distance,
          duration: duration,
          pickupLatitude: data.doubleValue('pickupLat'),
          pickupLongitude: data.doubleValue('pickupLng'),
          pickupAddress: data.string('pickupAddress'),
          passengerNote: data.string('passengerNote') ?? '',
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.driverMatched,
      TripRoutes.driverMatchedPath,
      child: (context, GoRouterState state) {
        final data = RoutePayload.from(extra: state.extra);
        final destination = data.object<PlaceModel>('destination');
        if (destination == null) {
          return const Scaffold(
            body: Center(child: Text('Destination data is unavailable.')),
          );
        }
        final fare = data.doubleValue('fare');
        final distance = data.string('distance');
        final duration = data.string('duration');
        if (fare == null || fare <= 0 || distance == null || duration == null) {
          return const Scaffold(
            body: Center(child: Text('Fare and trip data are unavailable.')),
          );
        }
        return DriverMatchedPage(
          rideType: data.string('rideType') ?? 'Solo Ride',
          fare: fare,
          destination: destination,
          distance: distance,
          duration: duration,
          driverId: data.string('driverId'),
          driverName: data.string('driverName'),
          driverRating: data.string('driverRating'),
          vehicleType: data.string('vehicleType'),
          plateNumber: data.string('plateNumber'),
          pickupAddress: data.string('pickupAddress'),
          createdRide: data.object<RideHistoryModel>('createdRide'),
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];

  static PlaceModel? _destinationFromQuery(RoutePayload data) {
    final name = data.string('destinationName');
    final latitude = data.doubleValue('destinationLat');
    final longitude = data.doubleValue('destinationLng');

    if (name == null ||
        name.trim().isEmpty ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    return PlaceModel(
      id: data.string('destinationId') ?? name,
      name: name,
      fullAddress: data.string('destinationAddress') ?? name,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
