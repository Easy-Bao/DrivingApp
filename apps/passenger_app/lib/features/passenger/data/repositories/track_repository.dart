import 'package:fixtures/fixtures.dart';
import 'package:core_models/core_models.dart';

class FixtureTrackRepository implements TrackRepository {
  @override
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.interpolateRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
  }
}

class MapboxTrackRepository implements TrackRepository {
  @override
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    // Imported lazily to avoid coupling the repo layer to the service layer.
    // When backend WebSocket provides live driver position, swap this out.
    // final route = await MapProvider.getRoute(startLat, startLng, endLat, endLng);
    // return route?.polylinePoints;
    throw UnimplementedError(
      'Wire MapProvider.getRoute here when integrating the live tracking backend.',
    );
  }
}

//TODO: Implement the real API repository once backend endpoints are ready and integrated.

// ignore: unused_element — will be used when backend is integrated
class _ApiTrackRepository implements TrackRepository {
  // final HttpClient _httpClient;
  // _ApiTrackRepository(this._httpClient);

  @override
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    // final response = await _httpClient.get('/route/polyline', queryParameters: {
    //   'startLat': startLat,
    //   'startLng': startLng,
    //   'endLat': endLat,
    //   'endLng': endLng,
    // });
    // return (response.data['points'] as List).map((p) => List<double>.from(p)).toList();
    throw UnimplementedError('Backend not yet integrated');
  }
}
