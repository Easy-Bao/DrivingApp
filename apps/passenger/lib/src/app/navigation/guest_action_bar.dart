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
    final signUp = _authButton(context, 'Sign up', onSignUp, primary: false);
    final signIn = _authButton(context, 'Log in', onSignIn, primary: true);
    final stackActions =
        MediaQuery.sizeOf(context).width < 300 ||
        MediaQuery.textScalerOf(context).scale(14) > 21;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(color: context.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.pagePadding,
            AppSpacing.md,
            AppLayout.pagePadding,
            AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stackActions)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    signUp,
                    const SizedBox(height: AppSpacing.md),
                    signIn,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: signUp),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: signIn),
                  ],
                ),
              TextButton(
                onPressed: onHelp,
                style: TextButton.styleFrom(
                  foregroundColor: context.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  minimumSize: const Size(48, 48),
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'Need help? ',
                    children: [
                      TextSpan(
                        text: 'Visit our Help Centre',
                        style: TextStyle(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authButton(
    BuildContext context,
    String label,
    VoidCallback onPressed, {
    required bool primary,
  }) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSize.minimumTouchTarget),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      backgroundColor: primary
          ? context.colorScheme.primary
          : context.colorScheme.secondaryContainer,
      foregroundColor: primary
          ? context.colorScheme.onPrimary
          : context.colorScheme.onSecondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    child: Text(label),
  );
}
