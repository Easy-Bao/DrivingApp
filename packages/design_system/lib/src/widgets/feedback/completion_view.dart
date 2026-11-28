import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

enum AppCompletionTone { success, info, warning }

class const AppCompletionView({
  super.key,
  required this.title,
  required this.message,
  required this.primaryActionLabel,
  required this.onPrimaryAction,
  this.secondaryActionLabel,
  this.onSecondaryAction,
  this.summary,
  this.footnote,
  this.icon,
  this.tone = AppCompletionTone.success,
  this.padding = const EdgeInsets.all(AppSpacing.xxl),
}) extends StatelessWidget {
  final String title;
  final String message;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? summary;
  final String? footnote;
  final IconData? icon;
  final AppCompletionTone tone;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final semanticColors = context.semanticColors;
    final textStyles = context.textStyles;

    final (containerColor, iconColor, defaultIcon) = switch (tone) {
      AppCompletionTone.success => (
        semanticColors.successContainer,
        semanticColors.onSuccessContainer,
        LucideIcons.check,
      ),
      AppCompletionTone.info => (
        semanticColors.infoContainer,
        semanticColors.onInfoContainer,
        LucideIcons.info,
      ),
      AppCompletionTone.warning => (
        semanticColors.warningContainer,
        semanticColors.onWarningContainer,
        LucideIcons.triangle_alert,
      ),
    };

    final hasSecondaryAction =
        secondaryActionLabel != null && onSecondaryAction != null;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ExcludeSemantics(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: containerColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon ?? defaultIcon, size: 30, color: iconColor),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textStyles.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: AppSpacing.xl),
            summary!,
          ],
          if (footnote != null && footnote!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              footnote!,
              textAlign: TextAlign.center,
              style: textStyles.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: onPrimaryAction,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSize.controlHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            child: Text(primaryActionLabel),
          ),
          if (hasSecondaryAction) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: onSecondaryAction,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSize.controlHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Text(secondaryActionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
