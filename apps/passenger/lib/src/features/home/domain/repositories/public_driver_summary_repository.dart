import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/home/domain/entities/public_driver_summary.dart';
import 'package:foundation/foundation.dart';

abstract interface class PublicDriverSummaryRepository {
  Future<Either<Failure, List<PublicDriverSummary>>> fetchSummaries();
}
