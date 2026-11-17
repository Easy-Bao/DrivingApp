import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:passenger/src/features/home/data/datasources/home_remote_data_source.dart';
import 'package:passenger/src/features/home/domain/entities/home_data.dart';
import 'package:passenger/src/features/home/domain/entities/recent_location.dart';
import 'package:passenger/src/features/home/domain/repositories/home_repository.dart';

final class HomeRepositoryImpl({required this._homeRemoteDataSource})
    implements HomeRepository {
  final HomeRemoteDataSource _homeRemoteDataSource;

  @override
  Future<Result<HomeData, Failure>> loadHomeData({
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
      return Ok(
        HomeData.fromList(
          currentAddress: rawAddress as String? ?? '',
          recentLocations: _parseRecentLocations(response['recent_locations']),
        ),
      );
    } catch (error) {
      return Err(_mapExceptionToFailure(error));
    }
  }

  List<RecentLocation> _parseRecentLocations(Object? rawLocations) {
    if (rawLocations is! List) {
      throw DataParsingException(
        message: 'Passenger home activity has an invalid format.',
      );
    }

    final locations = <RecentLocation>[];
    final seenTitles = <String>{};
    for (final rawLocation in rawLocations) {
      if (rawLocation is! Map) continue;
      final title = rawLocation['title']?.toString().trim() ?? '';
      final latitude = SafeParse.toNullableDouble(rawLocation['lat']);
      final longitude = SafeParse.toNullableDouble(rawLocation['lng']);
      if (title.isEmpty || latitude == null || longitude == null) continue;
      if (!seenTitles.add(title.toLowerCase())) continue;
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
      if (statusCode == 401) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (statusCode == 403) {
        return const ServerFailure.withStatusCode(
          'You do not have permission to view home data.',
          403,
        );
      }
    }
    if (error is ServerException) {
      if (error.statusCode == 401) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 403) {
        return const ServerFailure.withStatusCode(
          'You do not have permission to view home data.',
          403,
        );
      }
    }
    return FailureMapper.fromException(
      error,
      serverMessage: 'Home data is temporarily unavailable. Please try again.',
      validationMessage: 'Invalid home data request.',
    );
  }
}
