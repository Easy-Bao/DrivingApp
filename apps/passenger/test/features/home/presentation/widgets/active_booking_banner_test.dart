import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/home/presentation/widgets/active_booking_banner.dart';

void main() {
  testWidgets('renders waiting booking details with silent touch feedback', (
    tester,
  ) async {
    var actionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: ActiveBookingBanner(
            title: 'Waiting for driver',
            subtitle: 'Alex • SM City',
            tone: ActiveBookingBannerTone.active,
            isLoading: true,
            actionLabel: 'View',
            showActionArrow: true,
            onAction: () => actionCount++,
          ),
        ),
      ),
    );

    expect(find.text('Waiting for driver'), findsOneWidget);
    expect(find.text('Alex • SM City'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('View'));
    expect(actionCount, 1);

    final bannerInk = tester.widget<InkWell>(
      find.byKey(const Key('active-booking-banner')),
    );
    expect(bannerInk.enableFeedback, isFalse);
    expect(bannerInk.splashFactory, NoSplash.splashFactory);
    expect(
      bannerInk.overlayColor?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(
      bannerInk.overlayColor?.resolve({WidgetState.focused}),
      isNot(Colors.transparent),
    );
  });

  testWidgets(
    'replaces loading spinner with static icon under reduced motion',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: ActiveBookingBanner(
                title: 'Waiting for driver',
                subtitle: 'To Robinsons',
                tone: ActiveBookingBannerTone.active,
                isLoading: true,
                icon: LucideIcons.clock,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(LucideIcons.clock), findsOneWidget);
    },
  );

  testWidgets(
    'renders dismissible timeout notice without overflow on narrow screens',
    (tester) async {
      var retryCount = 0;
      var dismissCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 275,
                child: ActiveBookingBanner(
                  title: 'Driver timed out',
                  subtitle: 'No driver responded for Robinsons Place Mall.',
                  tone: ActiveBookingBannerTone.warning,
                  icon: LucideIcons.timer,
                  actionLabel: 'Retry',
                  announceLiveRegion: true,
                  onAction: () => retryCount++,
                  onDismiss: () => dismissCount++,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Driver timed out'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.byKey(const Key('active-booking-banner-dismiss')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Retry'));
      expect(retryCount, 1);

      await tester.tap(find.byKey(const Key('active-booking-banner-dismiss')));
      expect(dismissCount, 1);
    },
  );
}
