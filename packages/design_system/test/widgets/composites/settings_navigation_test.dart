import 'package:material_ui/material_ui.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('settings destinations keep a full touch target', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AppSettingsSection(
            label: 'Driver details',
            children: [
              AppSettingsNavigationTile(
                icon: LucideIcons.car_front,
                title: 'Vehicle information',
                subtitle: 'Motorcycle · Plate XYZ-123',
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    final destination = find.byKey(
      const ValueKey<String>('settings-destination-Vehicle information'),
    );
    expect(tester.getSize(destination).height, greaterThanOrEqualTo(48));

    await tester.tap(destination);
    expect(tapped, isTrue);
  });
}
