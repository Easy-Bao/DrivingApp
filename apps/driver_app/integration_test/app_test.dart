import 'package:driver_app/app_widget.dart' as widget;
import 'package:driver_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('verify app starts', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.byType(widget.AppWidget), findsOneWidget);
    });
  });
}
