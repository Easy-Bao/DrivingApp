import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/home/domain/entities/public_driver_summary.dart';

abstract interface class PublicDriverSummaryRepository {
  Future<Either<Failure, List<PublicDriverSummary>>> fetchSummaries();
}
