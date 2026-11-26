import 'package:design_system/src/theme/quiet_button_style.dart';
import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

/// Circular floating back button used over full-bleed map canvases.
class const AppMapBackButton({
  super.key,
  required this.onPressed,
  this.tooltip,
  this.semanticLabel,
  this.icon = LucideIcons.arrow_left,
}) extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final resolvedTooltip =
        tooltip ?? MaterialLocalizations.of(context).backButtonTooltip;
    return Tooltip(
      message: resolvedTooltip,
      child: Material(
        color: colors.surfaceContainerLowest,
        elevation: 1,
        shadowColor: colors.onSurface.withValues(alpha: 0.08),
        shape: CircleBorder(side: BorderSide(color: colors.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: semanticLabel ?? 'Back',
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            enableFeedback: false,
            splashFactory: NoSplash.splashFactory,
            overlayColor: AppQuietInteraction.focusOverlay(colors.primary),
            child: SizedBox(
              width: AppSize.minimumTouchTarget,
              height: AppSize.minimumTouchTarget,
              child: Center(
                child: Icon(icon, size: 19, color: colors.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
