import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/home/domain/entities/public_driver_summary.dart';

abstract interface class PublicDriverSummaryRepository {
  Future<Result<List<PublicDriverSummary>, Failure>> fetchSummaries();
}
