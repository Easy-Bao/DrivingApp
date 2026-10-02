import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/infrastructure/config/passenger_env_config.dart';

void main() {
  tearDown(dotenv.clean);

  test('reads the deployment environment from the app asset', () {
    dotenv.loadFromString(envString: 'APP_ENV=staging');

    expect(PassengerEnvConfig.appEnvironment, 'staging');
  });

  test('defaults the deployment environment for local development', () {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://127.0.0.1:8000');

    expect(PassengerEnvConfig.appEnvironment, 'development');
  });
}
