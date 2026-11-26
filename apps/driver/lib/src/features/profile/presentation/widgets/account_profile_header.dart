import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/account_snapshot.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const AccountProfileHeader({
  super.key,
  required this.account,
  required this.onTap,
}) extends StatelessWidget {
  final AccountSnapshot account;
  final VoidCallback onTap;

  String _initials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'D';
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = account.name.isEmpty ? 'Driver' : account.name;
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Semantics(
      button: true,
      label: '$displayName. View personal details',
      child: InkWell(
        key: const ValueKey<String>('driver-profile-summary'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  key: const ValueKey<String>('driver-profile-avatar'),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(displayName),
                    style: textStyles.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyles.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      account.phone.isEmpty
                          ? 'Add your mobile number'
                          : account.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyles.bodyMedium?.tabular.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Personal details',
                      style: textStyles.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.chevron_right,
                  size: 17,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
