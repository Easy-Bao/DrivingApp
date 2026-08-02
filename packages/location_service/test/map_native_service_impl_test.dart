import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_service/location_service.dart';

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
        if (options.uri.path == '/places/nearby') {
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
        if (options.uri.path == '/places/search') {
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
