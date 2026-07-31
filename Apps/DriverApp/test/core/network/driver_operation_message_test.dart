import 'package:core_models/core_models.dart';
import 'package:driver_app/src/Core/Network/DriverOperationsClient.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps driver operating blockers to actionable messages', () {
    expect(
      driverOperationMessage(
        ServerException(statusCode: 409, message: 'DRIVER_NOT_APPROVED'),
      ),
      contains('waiting for owner approval'),
    );
    expect(
      driverOperationMessage(
        ServerException(statusCode: 409, message: 'INSUFFICIENT_CREDIT'),
      ),
      contains('Top up before accepting'),
    );
    expect(
      driverOperationMessage(
        const DriverOperationException(
          code: 'ACCOUNT_RESTRICTED',
          message: 'restricted',
        ),
      ),
      contains('contact support'),
    );
  });
}
