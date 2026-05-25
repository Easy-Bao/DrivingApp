import 'package:BaoRide/src/rust/models/fare_models.dart';

abstract class DashboardRepository {
  Future<double> getTodayEarnings();

  Future<int> getTodayTrips();

  Future<double> getHoursOnline();
  Future<List<HeatmapCell>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  });
}

//TODO: Replace with real API implementation once backend endpoints are ready and integrated.

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<double> getTodayEarnings() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return 385.50;
  }

  @override
  Future<int> getTodayTrips() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 7;
  }

  @override
  Future<double> getHoursOnline() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 4.5;
  }

  @override
  Future<List<HeatmapCell>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      HeatmapCell(lat: lat + 0.002, lng: lng - 0.002, intensity: 2.5),
      HeatmapCell(lat: lat - 0.001, lng: lng + 0.003, intensity: 1.8),
      HeatmapCell(lat: lat + 0.005, lng: lng + 0.001, intensity: 3.1),
    ];
  }
}

//TODO: Implement the real API repository once backend endpoints are ready and integrated.

// ignore: unused_element — will be used when backend is integrated
class _ApiDashboardRepository implements DashboardRepository {
  // final HttpClient _httpClient;
  // ApiDashboardRepository(this._httpClient);

  @override
  Future<double> getTodayEarnings() async {
    // final response = await _httpClient.get('/driver/earnings/today');
    // return (response.data['earnings'] as num).toDouble();
    throw UnimplementedError('Backend not yet integrated');
  }

  @override
  Future<int> getTodayTrips() async {
    // final response = await _httpClient.get('/driver/trips/today');
    // return response.data['count'] as int;
    throw UnimplementedError('Backend not yet integrated');
  }

  @override
  Future<double> getHoursOnline() async {
    // final response = await _httpClient.get('/driver/hours-online/today');
    // return (response.data['hours'] as num).toDouble();
    throw UnimplementedError('Backend not yet integrated');
  }

  @override
  Future<List<HeatmapCell>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  }) async {
    // final response = await _httpClient.post('/map/surge', body: {...});
    // return (response.data['cells'] as List).map(HeatmapCell.fromJson).toList();
    throw UnimplementedError('Backend not yet integrated');
  }
}
