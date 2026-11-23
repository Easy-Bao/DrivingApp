import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

class const GuestActionBar({
  super.key,
  required this.onSignUp,
  required this.onSignIn,
}) extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final signUp = _authButton(context, 'Sign up', onSignUp, primary: false);
    final signIn = _authButton(context, 'Sign in', onSignIn, primary: true);
    final stackActions =
        MediaQuery.sizeOf(context).width < 300 ||
        MediaQuery.textScalerOf(context).scale(14) > 21;

    final colors = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.85)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.pagePadding,
            vertical: AppSpacing.md,
          ),
          child: stackActions
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    signUp,
                    const SizedBox(height: AppSpacing.md),
                    signIn,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: signUp),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: signIn),
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
  }) {
    final colors = context.colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style:
          FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSize.minimumTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            elevation: 0,
            enableFeedback: false,
            splashFactory: NoSplash.splashFactory,
            backgroundColor: primary
                ? colors.primary
                : colors.surfaceContainerLowest,
            foregroundColor: primary ? colors.onPrimary : colors.onSurface,
            side: primary ? null : BorderSide(color: colors.outlineVariant),
            textStyle: context.textStyles.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? (primary ? colors.onPrimary : colors.primary).withValues(
                      alpha: primary ? 0.16 : 0.12,
                    )
                  : Colors.transparent,
            ),
          ),
      child: Text(label),
    );
  }
}
