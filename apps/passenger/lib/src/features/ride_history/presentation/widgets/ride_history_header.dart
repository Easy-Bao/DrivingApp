import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class RideHistoryHeader extends StatelessWidget {
  const RideHistoryHeader({
    this.subtitle,
    this.title = 'Activity',
    this.showBackButton = false,
    super.key,
  });
  final String? subtitle;
  final String title;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    if (showBackButton) {
      final colors = context.colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey<String>('recent-activity-back-button'),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              style:
                  IconButton.styleFrom(
                    foregroundColor: colors.onSurface,
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
                LucideIcons.arrow_left,
                size: 19,
                color: colors.onSurface,
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 48, height: 48),
          ],
        ),
      );
    }

    return AppPageHeader(title: title, subtitle: subtitle);
  }
}
