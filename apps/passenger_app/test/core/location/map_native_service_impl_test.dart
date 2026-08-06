import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('MapNativeService Unit Tests', () {
    late Dio dio;
    late MapNativeService service;

    setUp(() {
      dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:8080',
          connectTimeout: const Duration(seconds: 5),
        ),
      );
      service = MapNativeService(
        placeServiceBaseUri: Uri.parse('http://localhost:8080'),
        dio: dio,
      );
    });

    test('getNearbyPois parses places JSON response correctly', () async {
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.uri.path == '/api/v1/location/nearby') {
          return ResponseBody.fromString(
            jsonEncode({
              'places': [
                {
                  'id': 'place_123',
                  'name': 'Mendero General Hospital',
                  'fullAddress': 'Mendero General Hospital, Pagadian City',
                  'latitude': 7.8282,
                  'longitude': 123.4361,
                  'category': 'hospital',
                  'distanceKm': 0.4,
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('Not Found', 404);
      });

      final result = await service.getNearbyPois(
        lat: 7.8282,
        lng: 123.4361,
        page: 1,
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left: $failure'), (
        places,
      ) {
        expect(places.length, equals(1));
        expect(places.first.name, equals('Mendero General Hospital'));
        expect(places.first.latitude, equals(7.8282));
        expect(places.first.longitude, equals(123.4361));
      });
    });

    test('searchPlaces parses places JSON response correctly', () async {
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.uri.path == '/api/v1/location/search') {
          return ResponseBody.fromString(
            jsonEncode({
              'places': [
                {
                  'id': 'search_1',
                  'name': 'Ben Sagun Elementary School',
                  'fullAddress': 'Ben Sagun, Pagadian City',
                  'latitude': 7.8282,
                  'longitude': 123.4361,
                  'category': 'school',
                  'distanceKm': 0.5,
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('Not Found', 404);
      });

      final result = await service.searchPlaces(query: 'Ben Sagun');

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left: $failure'), (
        places,
      ) {
        expect(places.length, equals(1));
        expect(places.first.name, equals('Ben Sagun Elementary School'));
      });
    });

    test('reverseGeocode handles 404 not found cleanly', () async {
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        return ResponseBody.fromString(jsonEncode({'error': 'Not found'}), 404);
      });

      final result = await service.reverseGeocode(lat: 0.0, lng: 0.0);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<PlaceNetworkError>());
      }, (_) => fail('Expected Left but got Right'));
    });

    test('reverseGeocode preserves Mapbox proximity metadata', () async {
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.uri.path == '/api/v1/location/reverse') {
          return ResponseBody.fromString(
            jsonEncode({
              'id': 'street.1',
              'name': 'Main Street',
              'address': 'Main Street, Tuburan',
              'lat': 7.8282,
              'lng': 123.4363,
              'match_type': 'road',
              'distance_meters': 24.5,
              'confidence': 0.82,
              'context': {'place': 'Tuburan', 'region': 'Zamboanga del Sur'},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('Not Found', 404);
      });

      final result = await service.reverseGeocode(lat: 7.8282, lng: 123.4361);

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected a place: $failure'), (place) {
        expect(place.matchType, equals('road'));
        expect(place.distanceMeters, equals(24.5));
        expect(place.confidence, equals(0.82));
        expect(place.context['place'], equals('Tuburan'));
        expect(place.displayName, equals('Near Main Street'));
      });
    });

    test('getDrivingDistances parses Matrix API distances', () async {
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.uri.path == '/api/v1/location/matrix') {
          return ResponseBody.fromString(
            jsonEncode({
              'distancesKm': [1.25, 3.5],
              'durationsMin': [4.0, 9.0],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('Not Found', 404);
      });

      final result = await service.getDrivingDistances(
        originLat: 7.8282,
        originLng: 123.4361,
        destinations: const [
          (lat: 7.83, lng: 123.44),
          (lat: 7.84, lng: 123.45),
        ],
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left: $failure'), (
        distances,
      ) {
        expect(distances, equals([1.25, 3.5]));
      });
    });

    test(
      'getRoute sends nested coordinates and parses backend route fields',
      () async {
        dio.httpClientAdapter = _MockHttpClientAdapter((options) {
          expect(options.data, {
            'origin': {'lat': 7.8242, 'lng': 123.435},
            'destination': {'lat': 7.83, 'lng': 123.44},
            'preference': 'fastest',
          });
          return ResponseBody.fromString(
            jsonEncode({
              'distance_km': 1.8,
              'duration_min': 6.5,
              'polyline': [
                [123.435, 7.8242],
                [123.44, 7.83],
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final result = await service.getRoute(
          originLat: 7.8242,
          originLng: 123.435,
          destLat: 7.83,
          destLng: 123.44,
        );

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected a route: $failure'), (route) {
          expect(route.polylinePoints, hasLength(2));
          expect(route.distanceKm, equals(1.8));
          expect(route.durationSeconds, equals(390));
        });
      },
    );
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) _handler;

  _MockHttpClientAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
