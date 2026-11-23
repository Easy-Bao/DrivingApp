import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const RecentRideHistoryEmptyState({required this.isGuest, super.key})
    extends StatelessWidget {
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isGuest ? LucideIcons.compass : LucideIcons.clock,
                  size: 21,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isGuest ? 'Your trips, in one place' : 'No recent trips yet',
                textAlign: TextAlign.center,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isGuest
                    ? 'Sign in or create an account to book rides and keep your trip history here.'
                    : 'Your recent ride history will appear here.',
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
