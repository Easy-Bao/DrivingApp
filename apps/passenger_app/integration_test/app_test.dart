import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:passenger_app/src/app/passenger_app.dart' as app_widget;
import 'package:passenger_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('verify app starts', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.byType(app_widget.PassengerApp), findsOneWidget);
    });
  });
}
