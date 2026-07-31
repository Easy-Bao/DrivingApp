import 'package:core_models/core_models.dart';
import 'package:driver_app/src/Core/Network/DriverOperationsClient.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps driver operating blockers to actionable messages', () {
    expect(
      driverOperationMessage(
        ServerException(statusCode: 409, message: 'DRIVER_NOT_APPROVED'),
      ),
      'Your driver account is not approved. Contact support before going online or accepting rides.',
    );
    expect(
      driverOperationMessage(
        ServerException(
          statusCode: 409,
          message: 'DRIVER_DOCUMENTS_INCOMPLETE',
        ),
      ),
      'Required driver documents are incomplete, rejected, or expired. Contact support before going online or accepting rides.',
    );
    expect(
      driverOperationMessage(
        ServerException(statusCode: 409, message: 'INSUFFICIENT_CREDIT'),
      ),
      'Your available service credits cannot cover this ride commission. Top up before accepting.',
    );
    expect(
      driverOperationMessage(
        const DriverOperationException(
          code: 'ACCOUNT_RESTRICTED',
          message: 'restricted',
        ),
      ),
      'Your account is restricted. You can still view credits and history; contact support for the reason.',
    );
  });
}
