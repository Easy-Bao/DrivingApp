import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/presentation/widgets/booking_auth_bottom_sheet.dart';

void main() {
  testWidgets('returns the selected authentication action and is dismissible', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final actionFuture = showBookingAuthBottomSheet(pageContext);
    await tester.pumpAndSettle();

    expect(find.text('Sign in to book a ride'), findsOneWidget);
    expect(find.text('Continue exploring'), findsNothing);
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isFalse,
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(await actionFuture, BookingAuthAction.signIn);
    expect(find.text('Sign in to book a ride'), findsNothing);

    final signUpFuture = showBookingAuthBottomSheet(pageContext);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(await signUpFuture, BookingAuthAction.signUp);
  });

  testWidgets('closes when the modal barrier is tapped', (tester) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final actionFuture = showBookingAuthBottomSheet(pageContext);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(await actionFuture, isNull);
    expect(find.text('Sign in to book a ride'), findsNothing);
  });

  testWidgets('closes when dragged downward', (tester) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final actionFuture = showBookingAuthBottomSheet(pageContext);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(BottomSheet), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(await actionFuture, isNull);
    expect(find.text('Sign in to book a ride'), findsNothing);
  });
}
