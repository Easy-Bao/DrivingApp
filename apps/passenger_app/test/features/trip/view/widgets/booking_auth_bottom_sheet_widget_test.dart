import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/view/widgets/booking_auth_bottom_sheet_widget.dart';

void main() {
  testWidgets('returns the selected authentication action and is dismissible', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final actionFuture = showModalBottomSheet<BookingAuthAction>(
      context: pageContext,
      builder: (_) => const BookingAuthBottomSheetWidget(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create an account to book'), findsOneWidget);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(await actionFuture, BookingAuthAction.signIn);
    expect(find.text('Create an account to book'), findsNothing);
  });
}
