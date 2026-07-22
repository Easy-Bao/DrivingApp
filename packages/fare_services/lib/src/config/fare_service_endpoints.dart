import 'package:session_service/session_service.dart';

class FareServiceEndpoints {
  FareServiceEndpoints._();

  static Uri get configsUri => EnvironmentConfig.httpBaseUri.replace(
        path: '/fares/configs',
      );

  static Uri get ratingConfigUri => EnvironmentConfig.httpBaseUri.replace(
        path: '/fares/rating-config',
      );

  static Uri get estimateUri => EnvironmentConfig.httpBaseUri.replace(
        path: '/fares/estimate',
      );

  static Uri get calculateFinalUri => EnvironmentConfig.httpBaseUri.replace(
        path: '/fares/calculate-final',
      );
}
