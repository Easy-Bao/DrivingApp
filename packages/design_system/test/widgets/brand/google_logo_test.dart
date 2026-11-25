import 'package:design_system/design_system.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('loads the shared Google vector asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GoogleLogo())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
