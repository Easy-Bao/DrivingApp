import 'package:core_domain/core_domain.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

class const TrackDriverPanel({
  super.key,
  required this.ride,
  required this.statusTitle,
  required this.statusSubtitle,
  required this.etaText,
  this.driverName,
  this.vehicleSummary,
  this.driverRating,
  this.driverAvatarUrl,
  required this.unreadChatMessagesCount,
  this.showContactActions = true,
  this.isCancellingTrip = false,
  this.isInTransit,
  required this.onChatDriverPressed,
  required this.onReportDriverPressed,
  required this.onCancelTripPressed,
}) extends StatelessWidget {
  final RideSnapshot ride;
  final String statusTitle;
  final String statusSubtitle;
  final String etaText;
  final String? driverName;
  final String? vehicleSummary;
  final String? driverRating;
  final String? driverAvatarUrl;
  final int unreadChatMessagesCount;
  final bool showContactActions;
  final bool isCancellingTrip;
  final bool? isInTransit;
  final VoidCallback onChatDriverPressed;
  final VoidCallback onReportDriverPressed;
  final VoidCallback onCancelTripPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final hairline = colors.outlineVariant.withValues(alpha: 0.7);
    final name = driverName?.trim().isNotEmpty == true
        ? driverName!.trim()
        : ride.displayDriverName;
    final vehicle = vehicleSummary?.trim().isNotEmpty == true
        ? vehicleSummary!.trim()
        : ride.displayVehicleSummary;
    final rating = driverRating?.trim().isNotEmpty == true
        ? driverRating!.trim()
        : ride.displayDriverRating;
    final onTrip = isInTransit ?? ride.status == 'in_transit';

    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.pagePadding,
          AppSpacing.md,
          AppLayout.pagePadding,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                Text(
                  statusTitle,
                  style: context.textStyles.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (etaText.trim().isNotEmpty)
                  Text(
                    etaText,
                    key: const ValueKey('live-trip-eta'),
                    style: context.textStyles.titleMedium?.tabular.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              statusSubtitle,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (ride.farePesos case final fare?) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Agreed fare',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      formatPesoAmount(fare),
                      textAlign: TextAlign.end,
                      style: context.textStyles.titleMedium?.tabular.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: hairline),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: AppNetworkImage(
                    imageUrl: driverAvatarUrl,
                    width: 46,
                    height: 46,
                    borderRadius: BorderRadius.circular(23),
                    fallbackIcon: LucideIcons.user_round,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: context.textStyles.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (rating != null && rating.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: context.semanticColors.rating,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: context.textStyles.labelSmall?.tabular
                                  .copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (showContactActions) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Badge(
                    isLabelVisible: unreadChatMessagesCount > 0,
                    label: Text('$unreadChatMessagesCount'),
                    child: IconButton.filledTonal(
                      tooltip: 'Message driver',
                      onPressed: onChatDriverPressed,
                      style:
                          IconButton.styleFrom(
                            enableFeedback: false,
                            splashFactory: NoSplash.splashFactory,
                          ).copyWith(
                            overlayColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.focused)
                                  ? colors.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                            ),
                          ),
                      icon: const Icon(LucideIcons.message_circle, size: 19),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: hairline),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onReportDriverPressed,
                style:
                    TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      minimumSize: const Size(0, AppSize.minimumTouchTarget),
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? colors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                    ),
                icon: const Icon(LucideIcons.flag, size: 16),
                label: const Text('Report issue'),
              ),
            ),
            if (!onTrip)
              OutlinedButton(
                style:
                    OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide.none,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      minimumSize: const Size.fromHeight(
                        AppSize.minimumTouchTarget,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      textStyle: context.textStyles.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? colors.error.withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                    ),
                onPressed: isCancellingTrip ? null : onCancelTripPressed,
                child: Text(isCancellingTrip ? 'Cancelling…' : 'Cancel ride'),
              ),
          ],
        ),
      ),
    );
  }
}
