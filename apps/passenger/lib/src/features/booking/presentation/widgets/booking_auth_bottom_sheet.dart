import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

enum BookingAuthAction() {
  signIn,
  signUp,
}

Future<BookingAuthAction?> showBookingAuthBottomSheet(
  BuildContext context, {
  String title = 'Sign in to book a ride',
  String message = 'Sign in or create an account to see your route and fare, then book your ride.',
}) {
  return showModalBottomSheet<BookingAuthAction>(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.colorScheme.surface,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    barrierColor: context.colorScheme.onSurface.withValues(alpha: 0.54),
    useSafeArea: true,
    builder: (_) => BookingAuthBottomSheet(title: title, message: message),
  );
}

class const BookingAuthBottomSheet({
  super.key,
  this.title = 'Sign in to book a ride',
  this.message = 'Sign in or create an account to see your route and fare, then book your ride.',
}) extends StatelessWidget {
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              LucideIcons.lock,
              size: 30,
              color: context.colorScheme.onSurface,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(BookingAuthAction.signIn),
                child: const Text('Sign in'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () =>
                    Navigator.of(context).pop(BookingAuthAction.signUp),
                child: const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
