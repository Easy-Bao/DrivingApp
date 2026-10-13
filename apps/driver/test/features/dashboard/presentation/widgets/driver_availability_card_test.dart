import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/driver_availability_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('online status uses a neutral card and semantic status pill', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    bool? requestedAvailability;

    await tester.pumpWidget(
      _buildCard(
        isOnline: true,
        onChanged: (value) => requestedAvailability = value,
      ),
    );

    final card = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = card.decoration! as BoxDecoration;
    final semantics = EasyRideTheme.main.extension<EasyRideSemanticColors>()!;
    final statusPill = tester.widget<Container>(
      find
          .ancestor(of: find.text('ONLINE'), matching: find.byType(Container))
          .first,
    );

    expect(decoration.color, EasyRideTheme.main.colorScheme.surface);
    expect(
      decoration.border,
      Border.all(color: EasyRideTheme.main.colorScheme.outlineVariant),
    );
    expect((statusPill.decoration! as BoxDecoration).color, semantics.online);
    expect(
      tester.widget<Text>(find.text('ONLINE')).style?.color,
      semantics.onSuccess,
    );
    expect(
      _contrastRatio(semantics.onSuccess, semantics.online),
      greaterThanOrEqualTo(4.5),
    );
    expect(find.text('Available for ride requests nearby'), findsOneWidget);

    final switchFinder = find.byType(Switch);
    expect(tester.getSize(switchFinder).height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Driver availability'), findsOneWidget);

    await tester.tap(switchFinder);
    expect(requestedAvailability, isFalse);
    semanticsHandle.dispose();
  });

  testWidgets('active ride reduces the availability card to a status row', (
    tester,
  ) async {
    await tester.pumpWidget(_buildCard(isOnline: true, hasActiveRide: true));

    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text('Active trip'), findsOneWidget);
    expect(find.text('Available for ride requests nearby'), findsNothing);
  });

  testWidgets('offline status retains clear copy and a neutral label', (
    tester,
  ) async {
    await tester.pumpWidget(_buildCard(isOnline: false));

    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('Switch online to start receiving rides'), findsOneWidget);

    final statusPill = tester.widget<Container>(
      find
          .ancestor(of: find.text('OFFLINE'), matching: find.byType(Container))
          .first,
    );
    expect(
      (statusPill.decoration! as BoxDecoration).color,
      EasyRideTheme.main.colorScheme.surfaceContainerHighest,
    );
  });
}

Widget _buildCard({
  required bool isOnline,
  bool isToggling = false,
  bool hasActiveRide = false,
  ValueChanged<bool>? onChanged,
}) {
  return MaterialApp(
    theme: EasyRideTheme.main,
    home: Scaffold(
      body: DriverAvailabilityCard(
        isOnline: isOnline,
        isToggling: isToggling,
        hasActiveRide: hasActiveRide,
        statusPulse: const AlwaysStoppedAnimation<double>(1),
        onChanged: onChanged,
      ),
    ),
  );
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = math.max(foregroundLuminance, backgroundLuminance);
  final darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}
