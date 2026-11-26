import 'package:design_system/design_system.dart';
import 'package:driver/src/core/formatters/value_formatters.dart';
import 'package:driver/src/features/ride_history/presentation/bloc/ride_history_state.dart';
import 'package:driver/src/features/ride_history/presentation/formatters/trip_history_grouper.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const TripHistoryRow({super.key, required this.trip, required this.onTap})
    extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final status = (valueAsString(trip['status']) ?? 'completed').toLowerCase();
    final isCompleted = status == 'completed';
    final statusColor = isCompleted
        ? context.semanticColors.success
        : colorScheme.error;
    final statusLabel = isCompleted
        ? 'Completed'
        : sentenceCase(status, 'Canceled');
    final fromName = valueAsString(trip['pickup_name']) ?? 'Pickup';
    final toName = valueAsString(trip['dropoff_name']) ?? 'Drop-off';
    final formattedFareAmount = fareInPesos(trip);
    final fareText = formattedFareAmount == null
        ? '—'
        : formatPesoAmount(formattedFareAmount);
    final tripTime = formatDriverTripClockTime(
      trip,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final rawDistance = trip['distance_km'];
    final distance =
        rawDistance is num && rawDistance.isFinite && rawDistance > 0
        ? DistanceFormatter.fromKilometers(rawDistance)
        : '—';

    return InkWell(
      key: ValueKey<String>(
        'driver-trip-row-${valueAsString(trip['id']) ?? tripTime}',
      ),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tripTime,
                    style: textStyles.labelMedium?.tabular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: textStyles.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (valueAsString(trip['booking_reference'])
                case final String reference when reference.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              TripReference(id: reference, compact: true),
            ],
            const SizedBox(height: AppSpacing.md),
            CompactRouteTimeline(pickup: fromName, dropoff: toName),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    distance,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyles.bodySmall?.tabular.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  fareText,
                  style: textStyles.titleSmall?.tabular.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ExcludeSemantics(
                  child: Icon(
                    LucideIcons.chevron_right,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class const TripHistoryLoadingSkeleton({
  super.key,
  required this.horizontalPadding,
}) extends StatelessWidget {
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final hairlineColor = context.colorScheme.outlineVariant.withValues(
      alpha: 0.7,
    );
    return Skeletonizer.zone(
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSpacing.xl,
          horizontalPadding,
          AppSpacing.xxxl,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        itemCount: 4,
        separatorBuilder: (_, _) =>
            Divider(height: 1, thickness: 1, color: hairlineColor),
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Bone.text(width: 68, fontSize: 12),
                  Bone.text(width: 72, fontSize: 12),
                ],
              ),
              SizedBox(height: 12),
              Bone.text(width: 190, fontSize: 14),
              SizedBox(height: 8),
              Bone.text(width: 150, fontSize: 14),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Bone.text(width: 56, fontSize: 12),
                  Bone.text(width: 64, fontSize: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const TripHistoryMessageState({
  super.key,
  required this.horizontalPadding,
  required this.title,
  required this.message,
  required this.icon,
  required this.onRefresh,
  this.actionLabel,
  this.onAction,
}) extends StatelessWidget {
  final double horizontalPadding;
  final String title;
  final String message;
  final IconData icon;
  final RefreshCallback onRefresh;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return RefreshIndicator(
      color: colorScheme.onSurface,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          84,
          horizontalPadding,
          84,
        ),
        children: [
          Center(
            child: ExcludeSemantics(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: textStyles.bodySmall?.copyWith(
                  height: 1.45,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (actionLabel case final label? when onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: onAction,
                style:
                    TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.focused)) {
                          return colorScheme.primary.withValues(alpha: 0.12);
                        }
                        return Colors.transparent;
                      }),
                    ),
                child: Text(label),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class const TripHistoryLoadMoreFooter({
  super.key,
  required this.state,
  required this.onLoadMore,
}) extends StatelessWidget {
  final TripHistoryState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      );
    }
    final isOffline = AppNetworkStatusScope.isUnavailableOf(context);
    final loadMoreError = isOffline ? null : state.loadMoreError;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
      child: Column(
        children: [
          if (loadMoreError != null) ...[
            Text(
              loadMoreError,
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          TextButton.icon(
            onPressed: onLoadMore,
            style:
                TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return colorScheme.primary.withValues(alpha: 0.12);
                    }
                    return Colors.transparent;
                  }),
                ),
            icon: const Icon(LucideIcons.chevron_down, size: 16),
            label: Text(loadMoreError == null ? 'Load more trips' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
