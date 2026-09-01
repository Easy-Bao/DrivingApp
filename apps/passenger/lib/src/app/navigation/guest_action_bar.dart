import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class const GuestActionBarWidget({
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
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
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
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: context.colorScheme.secondaryContainer,
                      foregroundColor: context.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Sign Up'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: context.colorScheme.onSurface,
                      foregroundColor: context.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Log In'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onHelp,
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
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
          ],
        ),
      ),
    );
  }
}
