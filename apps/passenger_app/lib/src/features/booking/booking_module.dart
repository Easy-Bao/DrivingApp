import 'package:dio/dio.dart';
import 'package:maps/maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/infrastructure/telemetry/passenger_background_telemetry.dart';
import 'package:passenger_app/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger_app/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/booking_remote_data_source.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/driver_discovery_remote_data_source.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/fare_remote_data_source.dart';
import 'package:passenger_app/src/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:passenger_app/src/features/booking/data/repositories/driver_repository_impl.dart';
import 'package:passenger_app/src/features/booking/data/repositories/fare_repository_impl.dart';
import 'package:passenger_app/src/features/booking/domain/repositories/booking_repository.dart';
import 'package:passenger_app/src/features/booking/domain/repositories/driver_repository.dart';
import 'package:passenger_app/src/features/booking/domain/repositories/fare_repository.dart';
import 'package:passenger_app/src/features/booking/booking_routes.dart';
import 'package:passenger_app/src/features/booking/presentation/view/destination_map_page.dart';
import 'package:passenger_app/src/features/booking/presentation/view/finding_driver_page.dart';
import 'package:passenger_app/src/features/booking/presentation/view/map_pin_page.dart';
import 'package:passenger_app/src/features/booking/presentation/view/ride_selection_page.dart';
import 'package:passenger_app/src/features/booking/presentation/view/search_destination_page.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class BookingModule._() {
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
      ..addLazySingleton<DriverRepository>(
        (i) => DriverRepositoryImpl(
          discoveryDataSource: i.get<DriverDiscoveryRemoteDataSource>(),
          locationRepository: i.get<LocationRepository>(),
        ),
      )
      ..addLazySingleton<BookingRepository>(
        (i) =>
            BookingRepositoryImpl(dataSource: i.get<BookingRemoteDataSource>()),
      )
      ..addLazySingleton<FareRepository>(
        (i) =>
            FareRepositoryImpl(remoteDataSource: i.get<FareRemoteDataSource>()),
      )
      ..addLazySingleton<BookingBloc>(
        (i) => BookingBloc(
          driverRepository: i.get<DriverRepository>(),
          bookingRepository: i.get<BookingRepository>(),
          driverProfileRepository: i.get<DriverProfileRepository>(),
          secureSessionService: i.get<PassengerSessionStore>(),
          inboxCubit: i.get<InboxCubit>(),
          backgroundTelemetryService: i.get<PassengerBackgroundTelemetry>(),
          realtimeClient: i.get<RealtimeWebSocketClient>(),
          lifecycleCoordinator: i.get<AppLifecycleCoordinator>(),
        ),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: BookingRoutes.searchDestination,
      BookingRoutes.searchDestinationPath,
      child: (context, GoRouterState state) => SearchDestinationPage(
        preselectedRideType: state.uri.queryParameters['rideType'],
        pickupAddress: state.uri.queryParameters['pickupAddress'],
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: BookingRoutes.destinationMap,
      BookingRoutes.destinationMapPath,
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
        return DestinationMapPage(
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
      name: BookingRoutes.mapPin,
      BookingRoutes.mapPinPath,
      child: (context, GoRouterState state) => const MapPinPage(),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: BookingRoutes.rideSelection,
      BookingRoutes.rideSelectionPath,
      child: (context, GoRouterState state) {
        final extra = state.extra;
        final data = RoutePayload.from(
          extra: extra,
          queryParameters: state.uri.queryParameters,
        );
        final destination = extra is Place
            ? extra
            : data.object<Place>('destination') ?? _destinationFromQuery(data);
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
            fareRepository: Modular.get<FareRepository>(),
          ),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: BookingRoutes.findingDriver,
      BookingRoutes.findingDriverPath,
      child: (context, GoRouterState state) {
        final data = RoutePayload.from(extra: state.extra);
        final destination = data.object<Place>('destination');
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
          profileRepository: Modular.get<DriverProfileRepository>(),
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];

  static Place? _destinationFromQuery(RoutePayload data) {
    final name = data.string('destinationName');
    final latitude = data.doubleValue('destinationLat');
    final longitude = data.doubleValue('destinationLng');

    if (name == null ||
        name.trim().isEmpty ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    return Place(
      id: data.string('destinationId') ?? name,
      name: name,
      fullAddress: data.string('destinationAddress') ?? name,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
