import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/home/data/data_sources/home_remote_data_source.dart';
import 'package:passenger_app/src/features/home/domain/entities/home_data.dart';
import 'package:passenger_app/src/features/home/domain/entities/recent_location.dart';
import 'package:passenger_app/src/features/home/domain/repositories/i_home_repository.dart';
import 'package:shared_core/shared_core.dart';

class HomeRepository implements IHomeRepository {
  final HomeRemoteDataSource _homeRemoteDataSource;

  HomeRepository({required HomeRemoteDataSource homeRemoteDataSource})
    : _homeRemoteDataSource = homeRemoteDataSource;

  @override
  Future<Either<Failure, HomeData>> loadHomeData({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _homeRemoteDataSource.fetchHomeData(
        lat: lat,
        lng: lng,
      );
      final rawAddress = response['current_address'];
      if (rawAddress != null && rawAddress is! String) {
        throw DataParsingException(
          message: 'Passenger home address has an invalid format.',
        );
      }
      return Right(
        HomeData(
          currentAddress: rawAddress as String? ?? '',
          recentLocations: _parseRecentLocations(response['recent_locations']),
        ),
      );
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  List<RecentLocation> _parseRecentLocations(Object? rawLocations) {
    if (rawLocations is! List) {
      throw DataParsingException(
        message: 'Passenger home activity has an invalid format.',
      );
    }

    final locations = <RecentLocation>[];
    for (final rawLocation in rawLocations) {
      if (rawLocation is! Map) continue;
      final title = rawLocation['title']?.toString().trim() ?? '';
      final latitude = SafeParse.toNullableDouble(rawLocation['lat']);
      final longitude = SafeParse.toNullableDouble(rawLocation['lng']);
      if (title.isEmpty || latitude == null || longitude == null) continue;
      locations.add(
        RecentLocation(
          title: title,
          subtitle: rawLocation['subtitle']?.toString() ?? 'Previous Trip',
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }
    return locations;
  }

  Failure _mapExceptionToFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      return switch (error.type) {
        DioExceptionType.connectionError => const NetworkFailure(
          'Unable to connect. Check your connection and try again.',
        ),
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => const ServerFailure.withStatusCode(
          'Home data request timed out.',
          504,
        ),
        _ => ServerFailure.withStatusCode(
          'Home data is temporarily unavailable. Please try again.',
          statusCode ?? 500,
        ),
      };
    }
    if (error is ServerException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid home data request.');
      }
      return ServerFailure.withStatusCode(
        'Home data is temporarily unavailable. Please try again.',
        error.statusCode,
      );
    }
    if (error is DataParsingException) {
      return FailureMapper.fromException(
        error,
        serverMessage:
            'Home data is temporarily unavailable. Please try again.',
      );
    }
    return const ServerFailure(
      'Home data is temporarily unavailable. Please try again.',
    );
  }
}
