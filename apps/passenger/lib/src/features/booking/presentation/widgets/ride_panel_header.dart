import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class RidePanelHeader extends StatelessWidget {
  const RidePanelHeader({
    super.key,
    required this.title,
    required this.details,
    required this.onClose,
    this.closeKey,
  });

  final String title;
  final String details;
  final VoidCallback onClose;
  final Key? closeKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          key: closeKey,
          onPressed: onClose,
          tooltip: 'Back to trip summary',
          constraints: const BoxConstraints.tightFor(
            width: AppSize.minimumTouchTarget,
            height: AppSize.minimumTouchTarget,
          ),
          padding: EdgeInsets.zero,
          style:
              IconButton.styleFrom(
                backgroundColor: colors.surfaceContainerLowest,
                foregroundColor: colors.onSurface,
                side: BorderSide(color: colors.outlineVariant),
                shape: const CircleBorder(),
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? colors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
              ),
          icon: Icon(
            LucideIcons.chevron_down,
            color: colors.onSurface,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                details,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
