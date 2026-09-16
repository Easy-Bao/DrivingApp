import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/home/presentation/widgets/active_ride_banner_widget.dart';

void main() {
  testWidgets('shows active ride details and resumes tracking', (tester) async {
    var resumeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: ActiveRideBannerWidget(
            statusText: 'Driver Has Arrived',
            driverName: 'Alex',
            vehicleInfo: 'Sedan • ABC-123',
            onResume: () => resumeCount++,
          ),
        ),
      ),
    );

    expect(find.text('Driver Has Arrived'), findsOneWidget);
    expect(find.text('Alex • Sedan • ABC-123'), findsOneWidget);
    expect(find.text('Resume Trip'), findsOneWidget);

    await tester.tap(find.text('Resume Trip'));
    expect(resumeCount, 1);
  });
}
