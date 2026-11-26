import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: context.canvasColor,
      titleSpacing: AppLayout.pagePadding,
      toolbarHeight: 72,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EasyRide',
            style: context.textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'DRIVER',
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class const DashboardStatusIndicator({
  super.key,
  required this.isOnline,
  required this.statusPulse,
}) extends StatelessWidget {
  final bool isOnline;
  final Animation<double> statusPulse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final onlineColor = context.semanticColors.online;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: AnimatedBuilder(
            animation: statusPulse,
            builder: (context, child) {
              final borderOpacity = isOnline
                  ? 0.25 + statusPulse.value * 0.25
                  : 1.0;
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isOnline
                      ? onlineColor.withValues(alpha: 0.06)
                      : colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOnline
                        ? onlineColor.withValues(alpha: borderOpacity)
                        : colorScheme.outlineVariant,
                  ),
                ),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: Icon(
              isOnline ? LucideIcons.radio : LucideIcons.car_front,
              size: 22,
              color: isOnline ? onlineColor : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isOnline ? 'Ready for your next ride' : "You're offline",
          textAlign: TextAlign.center,
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            isOnline
                ? 'New ride requests will appear here.'
                : 'Switch online when you’re ready to drive.',
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
