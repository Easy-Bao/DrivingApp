import 'package:driver/src/features/active_ride/presentation/widgets/in_transit/in_transit_completion_slider.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/ride_confirmation_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('completing a trip requires a deliberate slide', (tester) async {
    var progress = 0.0;
    var completionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => InTransitCompletionSlider(
                progress: progress,
                onProgressChanged: (value) => setState(() => progress = value),
                onCompleteTripPressed: () => completionCount++,
              ),
            ),
          ),
        ),
      ),
    );

    final semantics = tester.ensureSemantics();
    final thumb = find.byIcon(LucideIcons.chevron_right);
    final slider = find.byKey(
      const ValueKey<String>('ride-confirmation-slider'),
    );
    final semanticsNode = tester.getSemantics(
      find.bySemanticsLabel('Slide to complete trip'),
    );

    expect(semanticsNode.flagsCollection.isSlider, isTrue);
    expect(find.text('Slide to complete trip'), findsOneWidget);

    await tester.tap(thumb);
    await tester.pump();
    expect(completionCount, 0);

    final travel =
        tester.getSize(slider).width - RideConfirmationSlider.thumbSize;
    await tester.timedDrag(
      thumb,
      Offset(travel * 0.5, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();
    expect(progress, 0);
    expect(completionCount, 0);

    await tester.timedDrag(
      thumb,
      Offset(travel * 0.9, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();
    expect(completionCount, 1);
    semantics.dispose();
  });
}
