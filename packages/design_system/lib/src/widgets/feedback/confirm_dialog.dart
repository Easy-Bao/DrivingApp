import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';

enum AppConfirmDialogTone { neutral, info, warning, destructive, success }

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  Key? confirmButtonKey,
  Key? cancelButtonKey,
  IconData? icon,
  AppConfirmDialogTone tone = AppConfirmDialogTone.neutral,
  bool isDestructive = false,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (dialogContext) => AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      confirmButtonKey: confirmButtonKey,
      cancelButtonKey: cancelButtonKey,
      icon: icon,
      tone: tone,
      isDestructive: isDestructive,
      canPop: barrierDismissible,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: cancelLabel != null
          ? () => Navigator.of(dialogContext).pop(false)
          : null,
    ),
  );
  return result ?? false;
}

class const AppConfirmDialog({
  super.key,
  required this.title,
  required this.message,
  required this.confirmLabel,
  required this.onConfirm,
  this.cancelLabel,
  this.onCancel,
  this.confirmButtonKey,
  this.cancelButtonKey,
  this.icon,
  this.tone = AppConfirmDialogTone.neutral,
  this.isDestructive = false,
  this.canPop = true,
}) extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final Key? confirmButtonKey;
  final Key? cancelButtonKey;
  final IconData? icon;
  final AppConfirmDialogTone tone;
  final bool isDestructive;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final semanticColors = context.semanticColors;
    final textStyles = context.textStyles;

    final (badgeBg, badgeFg) = switch (tone) {
      AppConfirmDialogTone.neutral => (
        colors.surfaceContainerHighest,
        colors.onSurface,
      ),
      AppConfirmDialogTone.info => (
        semanticColors.infoContainer,
        semanticColors.onInfoContainer,
      ),
      AppConfirmDialogTone.warning => (
        semanticColors.warningContainer,
        semanticColors.onWarningContainer,
      ),
      AppConfirmDialogTone.destructive => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      AppConfirmDialogTone.success => (
        semanticColors.successContainer,
        semanticColors.onSuccessContainer,
      ),
    };

    final confirmButton = FilledButton(
      key: confirmButtonKey,
      onPressed: onConfirm,
      style: FilledButton.styleFrom(
        minimumSize: const Size(
          AppSize.minimumTouchTarget,
          AppSize.minimumTouchTarget,
        ),
        backgroundColor: isDestructive ? colors.error : colors.primary,
        foregroundColor: isDestructive ? colors.onError : colors.onPrimary,
        elevation: 0,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Text(confirmLabel),
    );

    final cancelButton = cancelLabel == null
        ? null
        : OutlinedButton(
            key: cancelButtonKey,
            onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                AppSize.minimumTouchTarget,
                AppSize.minimumTouchTarget,
              ),
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outlineVariant),
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(cancelLabel!),
          );

    return PopScope(
      canPop: canPop,
      child: Dialog(
        backgroundColor: colors.surfaceContainerLowest,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 22, color: badgeFg),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: textStyles.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (cancelButton == null)
                  confirmButton
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackActions =
                          constraints.maxWidth < 260 ||
                          MediaQuery.textScalerOf(context).scale(14) > 20;
                      if (stackActions) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            confirmButton,
                            const SizedBox(height: AppSpacing.sm),
                            cancelButton,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: cancelButton),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: confirmButton),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
