import 'dart:typed_data';

import 'package:foundation/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/src/data/services/map_http_service.dart';
import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';
import 'package:maps/src/domain/failures/place_failure.dart';
import 'package:maps/src/presentation/annotation_service.dart';
import 'package:maps/src/presentation/app_map_view.dart';
import 'package:maps/src/presentation/camera_service.dart';
import 'package:maps/src/presentation/map_lookup_service.dart';
import 'package:material_ui/material_ui.dart' hide Route;

export 'package:maps/src/presentation/annotation_service.dart';
export 'package:maps/src/presentation/app_map_view.dart';
export 'package:maps/src/presentation/camera_service.dart';
export 'package:maps/src/presentation/map_lookup_service.dart';

class MapProvider._() {
  static const double nearbyRadiusKm = MapLookupService.nearbyRadiusKm;
  static const double fallbackNearbyRadiusKm =
      MapLookupService.fallbackNearbyRadiusKm;
  static bool _initialized = false;

  static String styleUriFor() => mapbox.MapboxStyles.MAPBOX_STREETS;

  static Future<void> initialize({
    String? token,
    required MapNativeService nativeService,
  }) async {
    if (_initialized) return;
    MapLookupService.configure(nativeService);
    if (token != null && token.isNotEmpty) {
      mapbox.MapboxOptions.setAccessToken(token);
    }
    _initialized = true;
  }

  /// Drops values that may have been resolved before a background network
  /// transition. The next visible feature request must reach the server
  /// instead of reusing a stale empty or route response.
  static void clearLookupCaches() => MapLookupService.clearLookupCaches();

  static Future<Result<List<Place>, PlaceFailure>> searchPlacesResult(
    String query, {
    double? latitude,
    double? longitude,
  }) => MapLookupService.searchPlacesResult(
    query,
    latitude: latitude,
    longitude: longitude,
  );

  static Future<List<Place>> searchPlaces(
    String query, {
    double? latitude,
    double? longitude,
  }) => MapLookupService.searchPlaces(
    query,
    latitude: latitude,
    longitude: longitude,
  );

  static Future<Place?> getPlaceFromCoordinates(
    double latitude,
    double longitude,
  ) => MapLookupService.getPlaceFromCoordinates(latitude, longitude);

  static Future<Route?> getRoute(
    double originLatitude,
    double originLongitude,
    double destinationLatitude,
    double destinationLongitude, {
    RoutePreference preference = RoutePreference.fastest,
    RouteProfile profile = RouteProfile.driving,
    List<({double latitude, double longitude})> excludePoints = const [],
  }) => MapLookupService.getRoute(
    originLatitude,
    originLongitude,
    destinationLatitude,
    destinationLongitude,
    preference: preference,
    profile: profile,
    excludePoints: excludePoints,
  );

  static Future<List<double>?> getDrivingDistances({
    required double originLatitude,
    required double originLongitude,
    required List<({double latitude, double longitude})> destinations,
  }) => MapLookupService.getDrivingDistances(
    originLatitude: originLatitude,
    originLongitude: originLongitude,
    destinations: destinations,
  );

  static Future<Result<List<Place>, PlaceFailure>> getNearbyPOIsResult({
    required double latitude,
    required double longitude,
    int page = 1,
  }) => MapLookupService.getNearbyPOIsResult(
    latitude: latitude,
    longitude: longitude,
    page: page,
  );

  static Future<List<Place>> getNearbyPOIs({
    required double latitude,
    required double longitude,
    int page = 1,
  }) => MapLookupService.getNearbyPOIs(
    latitude: latitude,
    longitude: longitude,
    page: page,
  );

  static Widget buildMapView({
    required double latitude,
    required double longitude,
    double zoom = 14.0,
    void Function(AppMapController controller)? onMapCreated,
    VoidCallback? onMapLoaded,
    void Function(AppMapController controller)? onCameraChanged,
    void Function(AppMapController controller)? onMapIdle,
    bool interactive = true,
    bool showUserLocation = false,
    EdgeInsets? padding,
  }) {
    return AppMapView(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
      styleUri: styleUriFor(),
      onMapCreated: onMapCreated,
      onMapLoaded: onMapLoaded,
      onCameraChanged: onCameraChanged,
      onMapIdle: onMapIdle,
      interactive: interactive,
      showUserLocation: showUserLocation,
      padding: padding,
    );
  }

  static Future<void> moveCamera(
    AppMapController controller,
    double lat,
    double lng, {
    double? zoom,
    EdgeInsets? viewportPadding,
    bool animate = true,
  }) => MapCameraService.moveCamera(
    controller,
    lat,
    lng,
    zoom: zoom,
    viewportPadding: viewportPadding,
    animate: animate,
  );

  static Future<LatLng> getCameraCenter(AppMapController controller) =>
      MapCameraService.getCameraCenter(controller);

  static Future<Offset> getScreenCoordinate(
    AppMapController controller,
    double lat,
    double lng,
  ) => MapCameraService.getScreenCoordinate(controller, lat, lng);

  static Future<void> fitBounds(
    AppMapController controller,
    List<LatLng> points, {
    double padding = 80.0,
    EdgeInsets? viewportPadding,
    double? maxZoom,
  }) => MapCameraService.fitBounds(
    controller,
    points,
    padding: padding,
    viewportPadding: viewportPadding,
    maxZoom: maxZoom,
  );

  static Future<mapbox.PointAnnotationManager> addMarker(
    AppMapController controller,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
    double? bearing,
    VoidCallback? onTap,
  }) => MapAnnotationService.addMarker(
    controller,
    lat,
    lng,
    label: label,
    isOrigin: isOrigin,
    color: color,
    bearing: bearing,
    onTap: onTap,
  );

  static Future<void> replaceMarker(
    mapbox.PointAnnotationManager annotationManager,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
    double? bearing,
    bool animate = false,
  }) => MapAnnotationService.replaceMarker(
    annotationManager,
    lat,
    lng,
    label: label,
    isOrigin: isOrigin,
    color: color,
    bearing: bearing,
    animate: animate,
  );

  static Future<mapbox.PolylineAnnotationManager> addPolyline(
    AppMapController controller,
    List<List<double>> points, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => MapAnnotationService.addPolyline(
    controller,
    points,
    color: color,
    width: width,
  );

  static Future<mapbox.PolylineAnnotationManager> addPolylineBuffer(
    AppMapController controller,
    Float64List coordinates, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => MapAnnotationService.addPolylineBuffer(
    controller,
    coordinates,
    color: color,
    width: width,
  );

  static Future<void> replacePolyline(
    mapbox.PolylineAnnotationManager annotationManager,
    List<List<double>> points, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => MapAnnotationService.replacePolyline(
    annotationManager,
    points,
    color: color,
    width: width,
  );

  static Future<void> replacePolylineBuffer(
    mapbox.PolylineAnnotationManager annotationManager,
    Float64List coordinates, {
    Color color = TripMapMarkerStyle.ownLocation,
    double width = 4.0,
  }) => MapAnnotationService.replacePolylineBuffer(
    annotationManager,
    coordinates,
    color: color,
    width: width,
  );

  static Future<void> clearAnnotations(mapbox.BaseAnnotationManager? manager) =>
      MapAnnotationService.clearAnnotations(manager);
}
