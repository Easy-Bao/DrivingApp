import 'package:core_models/core_models.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/activity_detail_map_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/destination_preview_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/driver_matched_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/finding_driver_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/map_pin_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/ride_selection_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/search_destination_screen.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class TripModule {
  TripModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: TripRoutes.searchDestination,
      'home/search',
      child: (context, GoRouterState state) => SearchDestinationScreen(
        preselectedRideType: state.uri.queryParameters['rideType'],
        pickupAddress: state.uri.queryParameters['pickupAddress'],
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.activityDetailMap,
      'home/activity-detail',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return ActivityDetailMapScreen(
          placeName: data['title'] as String? ?? 'Location Detail',
          placeSubtitle: data['subtitle'] as String? ?? '',
          destinationLat: (data['lat'] as num?)?.toDouble() ?? 14.5995,
          destinationLng: (data['lng'] as num?)?.toDouble() ?? 120.9842,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.mapPin,
      'home/map-pin',
      child: (context, GoRouterState state) => const MapPinScreen(),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.destinationPreview,
      'home/destination-preview',
      child: (context, GoRouterState state) {
        PlaceModel? place;
        if (state.extra is PlaceModel) {
          place = state.extra as PlaceModel;
        } else if (state.extra is Map) {
          final map = state.extra as Map;
          if (map['destination'] is PlaceModel) {
            place = map['destination'] as PlaceModel;
          }
        }

        place ??= PlaceModel(
          id: 'dest_${DateTime.now().millisecondsSinceEpoch}',
          name: state.uri.queryParameters['destinationName'] ??
              'Selected Destination',
          fullAddress:
              state.uri.queryParameters['destinationAddress'] ?? '',
          latitude: double.tryParse(
                state.uri.queryParameters['destinationLat'] ?? '',
              ) ??
              14.5995,
          longitude: double.tryParse(
                state.uri.queryParameters['destinationLng'] ?? '',
              ) ??
              120.9842,
        );

        return DestinationPreviewScreen(
          destination: place,
          preselectedRideType: state.uri.queryParameters['rideType'],
          pickupAddress: state.uri.queryParameters['pickupAddress'],
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.rideSelection,
      'home/ride-selection',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        final destination = data['destination'] is PlaceModel
            ? data['destination'] as PlaceModel
            : PlaceModel(
                id: 'dest_${DateTime.now().millisecondsSinceEpoch}',
                name: state.uri.queryParameters['destinationName'] ??
                    'Selected Destination',
                fullAddress:
                    state.uri.queryParameters['destinationAddress'] ?? '',
                latitude: double.tryParse(
                      state.uri.queryParameters['destinationLat'] ?? '',
                    ) ??
                    14.5995,
                longitude: double.tryParse(
                      state.uri.queryParameters['destinationLng'] ?? '',
                    ) ??
                    120.9842,
              );
          Map<String, double>? fares;
          if (data['fares'] is Map) {
            fares = (data['fares'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            );
          }
          return RideSelectionScreen(
            destination: destination,
            distance: data['distance'] as String? ??
                state.uri.queryParameters['distance'] ??
                '0.0 km',
            duration: data['duration'] as String? ??
                state.uri.queryParameters['duration'] ??
                '0 min',
            distanceKm: (data['distanceKm'] as num?)?.toDouble() ??
                double.tryParse(
                  state.uri.queryParameters['distanceKm'] ?? '',
                ) ??
                0.0,
            fares: fares,
            pickupAddress: data['pickupAddress'] as String? ??
                state.uri.queryParameters['pickupAddress'],
          );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.findingDriver,
      'home/finding-driver',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        final destination = data['destination'] is PlaceModel
            ? data['destination'] as PlaceModel
            : PlaceModel(
                id: 'dest_${DateTime.now().millisecondsSinceEpoch}',
                name: state.uri.queryParameters['destinationName'] ??
                    'Destination',
                fullAddress:
                    state.uri.queryParameters['destinationAddress'] ?? '',
                latitude: 14.5995,
                longitude: 120.9842,
              );
        return FindingDriverScreen(
          rideType: data['rideType'] as String? ?? 'Solo Ride',
          fare: (data['fare'] as num?)?.toDouble() ?? 0.0,
          destination: destination,
          distance: data['distance'] as String? ?? '0.0 km',
          duration: data['duration'] as String? ?? '0 min',
          pickupAddress: data['pickupAddress'] as String?,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.driverMatched,
      'home/driver-matched',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        final destination = data['destination'] is PlaceModel
            ? data['destination'] as PlaceModel
            : PlaceModel(
                id: 'dest_${DateTime.now().millisecondsSinceEpoch}',
                name: state.uri.queryParameters['destinationName'] ??
                    'Destination',
                fullAddress:
                    state.uri.queryParameters['destinationAddress'] ?? '',
                latitude: 14.5995,
                longitude: 120.9842,
              );
        return DriverMatchedScreen(
          rideType: data['rideType'] as String? ?? 'Solo Ride',
          fare: (data['fare'] as num?)?.toDouble() ?? 0.0,
          destination: destination,
          distance: data['distance'] as String? ?? '0.0 km',
          duration: data['duration'] as String? ?? '0 min',
          driverId: data['driverId'] as String?,
          driverName: data['driverName'] as String?,
          driverRating: data['driverRating'] as String?,
          vehicleType: data['vehicleType'] as String?,
          plateNumber: data['plateNumber'] as String?,
          pickupAddress: data['pickupAddress'] as String?,
          createdRide: data['createdRide'] as RideHistoryModel?,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}
