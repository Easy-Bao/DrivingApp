import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

void main() {
  testWidgets('settings destinations keep a full touch target', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: AppSettingsScaffold(
          onBack: () {},
          children: [
            AppSettingsSection(
              label: 'Device',
              children: [
                AppSettingsNavigationTile(
                  icon: LucideIcons.map_pin,
                  title: 'Location access',
                  subtitle: 'Ready for pickups',
                  onTap: () => tapped = true,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final destination = find.byKey(
      const ValueKey<String>('settings-destination-Location access'),
    );
    expect(tester.getSize(destination).height, greaterThanOrEqualTo(76));

    await tester.tap(destination);
    expect(tapped, isTrue);
  });

  testWidgets('about and terms pages expose completed content', (tester) async {
    var openedLicenses = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: AppAboutPage(
          applicationName: 'BaoRide Driver',
          applicationVersion: '1.0.0',
          description: 'Driver tools and trip information.',
          icon: LucideIcons.car_front,
          onBack: () {},
          onLicensesTap: () => openedLicenses = true,
        ),
      ),
    );

    expect(find.text('BaoRide Driver'), findsOneWidget);
    await tester.tap(find.text('Open-source licenses'));
    expect(openedLicenses, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: AppTermsOfServicePage(onBack: () {}),
      ),
    );
    expect(find.text('BaoRide Terms of Service'), findsOneWidget);
    expect(find.text('Account responsibility'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
