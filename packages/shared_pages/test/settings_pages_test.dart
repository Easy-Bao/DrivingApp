import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_pages/shared_pages.dart';

void main() {
  testWidgets('about and terms pages expose completed content', (tester) async {
    var openedLicenses = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: AppAboutPage(
          applicationName: 'EasyRide Driver',
          applicationVersion: '1.0.0',
          description: 'Driver tools and trip information.',
          icon: LucideIcons.car_front,
          onBack: () {},
          onLicensesTap: () => openedLicenses = true,
        ),
      ),
    );

    expect(find.text('EasyRide Driver'), findsOneWidget);
    await tester.tap(find.text('Open-source licenses'));
    expect(openedLicenses, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: AppTermsOfServicePage(onBack: () {}),
      ),
    );
    expect(find.text('EasyRide Terms of Service'), findsOneWidget);
    expect(
      find.text('Account responsibility', skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
