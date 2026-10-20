import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class const GuestActionBar({
  super.key,
  required this.onSignUp,
  required this.onSignIn,
  required this.onHelp,
}) extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.pagePaddingWide,
          14,
          AppLayout.pagePaddingWide,
          12,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          border: Border(
            top: BorderSide(color: context.colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onSignUp,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppSize.controlHeight),
                      backgroundColor: context.colorScheme.secondaryContainer,
                      foregroundColor: context.colorScheme.onSecondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Text('Sign Up'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(
                  child: FilledButton(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppSize.controlHeight),
                      backgroundColor: context.colorScheme.onSurface,
                      foregroundColor: context.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Text('Log In'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'Need help? Visit our Help Centre',
              child: TextButton(
                onPressed: onHelp,
                style: TextButton.styleFrom(
                  foregroundColor: context.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 48),
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: context.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: 'Need help? '),
                      TextSpan(
                        text: 'Visit our Help Centre',
                        style: TextStyle(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
