import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/home/domain/entities/public_driver_summary.dart';
import 'package:shared_core/shared_core.dart';

abstract class IPublicDriverSummaryRepository {
  Future<Either<Failure, List<PublicDriverSummary>>> fetchSummaries();
}
