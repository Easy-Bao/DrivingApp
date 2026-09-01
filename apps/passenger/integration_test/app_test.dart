import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:passenger/main.dart' as app;
import 'package:passenger/src/app/passenger_app.dart' as app_widget;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('verify app starts', (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      expect(find.byType(app_widget.PassengerApp), findsOneWidget);
    });
  });
}
