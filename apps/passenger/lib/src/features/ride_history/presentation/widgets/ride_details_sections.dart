import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_details_map.dart';

class RideDetailsSectionLabel extends StatelessWidget {
  const RideDetailsSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.85,
        ),
      ),
    );
  }
}

class RideDetailsDriverSection extends StatelessWidget {
  const RideDetailsDriverSection({
    super.key,
    required this.driverName,
    required this.vehicleSummary,
    required this.showLostFoundChat,
    required this.canCallDriver,
    required this.contactError,
    required this.onMessageDriver,
    required this.onCallDriver,
  });

  final String driverName;
  final String vehicleSummary;
  final bool showLostFoundChat;
  final bool canCallDriver;
  final String? contactError;
  final VoidCallback onMessageDriver;
  final VoidCallback onCallDriver;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RideDetailsSectionLabel('DRIVER'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Text(
                _driverInitials(driverName),
                style: context.textStyles.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    style: context.textStyles.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicleSummary,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (showLostFoundChat) ...[
              const SizedBox(width: AppSpacing.sm),
              _RideDetailsContactButton(
                tooltip: 'Message driver',
                icon: LucideIcons.message_circle,
                onPressed: onMessageDriver,
              ),
            ],
            if (showLostFoundChat && canCallDriver) ...[
              const SizedBox(width: AppSpacing.xs),
              _RideDetailsContactButton(
                tooltip: 'Call driver',
                icon: LucideIcons.phone,
                onPressed: onCallDriver,
              ),
            ],
          ],
        ),
        if (contactError case final error?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: context.textStyles.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }

  static String _driverInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'D';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class _RideDetailsContactButton extends StatelessWidget {
  const _RideDetailsContactButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(
        width: AppSize.minimumTouchTarget,
        height: AppSize.minimumTouchTarget,
      ),
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
      icon: Icon(icon, size: 18),
    );
  }
}

class RideDetailsRouteSection extends StatelessWidget {
  const RideDetailsRouteSection({
    super.key,
    required this.statusLabel,
    required this.isCompleted,
    required this.pickupLabel,
    required this.dropoffLabel,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.distanceKm,
    this.durationMinutes,
  });

  final String statusLabel;
  final bool isCompleted;
  final String pickupLabel;
  final String dropoffLabel;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final double? distanceKm;
  final double? durationMinutes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final pLat = pickupLatitude;
    final pLng = pickupLongitude;
    final dLat = dropoffLatitude;
    final dLng = dropoffLongitude;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            const RideDetailsSectionLabel('ROUTE'),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isCompleted
                      ? context.semanticColors.success.withValues(alpha: 0.4)
                      : colors.outlineVariant,
                ),
              ),
              child: Text(
                statusLabel,
                style: context.textStyles.labelSmall?.copyWith(
                  color: isCompleted
                      ? context.semanticColors.success
                      : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (pLat != null &&
            pLng != null &&
            dLat != null &&
            dLng != null &&
            (pLat != 0 || pLng != 0) &&
            (dLat != 0 || dLng != 0)) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 180,
              child: RideDetailsMap(
                key: ValueKey((pLat, pLng, dLat, dLng)),
                pickupLatitude: pLat,
                pickupLongitude: pLng,
                dropoffLatitude: dLat,
                dropoffLongitude: dLng,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (distanceKm != null || durationMinutes != null) ...[
          Text(
            [
              if (distanceKm case final distance?)
                distance < 1
                    ? '${(distance * 1000).round()} m'
                    : '${distance.toStringAsFixed(1)} km',
              if (durationMinutes case final duration?)
                '${duration.round()} min',
            ].join(' · '),
            style: context.textStyles.labelSmall?.tabular.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        CompactRouteTimeline(pickup: pickupLabel, dropoff: dropoffLabel),
      ],
    );
  }
}

class RideDetailsFareBreakdown extends StatelessWidget {
  const RideDetailsFareBreakdown({
    super.key,
    required this.snapshot,
    required this.fare,
  });

  final RideSnapshot? snapshot;
  final double? fare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final cashReceivedAmount = snapshot?.cashReceivedAmount;
    final cashChangeAmount = snapshot?.cashChangeAmount;
    final resolvedFare = fare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RideDetailsSectionLabel('FARE BREAKDOWN'),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                'Total fare',
                style: context.textStyles.bodyLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                resolvedFare == null
                    ? 'Fare unavailable'
                    : formatPesoAmount(resolvedFare),
                key: const ValueKey('receipt-total-fare'),
                textAlign: TextAlign.end,
                style: context.textStyles.titleLarge?.tabular.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Cash · ${_cashPaymentStatus(snapshot)}',
          style: context.textStyles.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (snapshot?.cashSettled == true &&
            cashReceivedAmount != null &&
            cashReceivedAmount > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cash received ${formatPesoAmount(cashReceivedAmount / 100)}'
            '${cashChangeAmount != null && cashChangeAmount > 0 ? ' · Change ${formatPesoAmount(cashChangeAmount / 100)}' : ''}',
            style: context.textStyles.bodySmall?.tabular.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  static String _cashPaymentStatus(RideSnapshot? ride) {
    if (ride == null) return 'Status unavailable.';
    if (!ride.cashSettled) return 'Awaiting driver confirmation.';
    return switch (ride.cashOutcome) {
      'paid' => 'Driver confirmed cash received.',
      'partial' => 'Driver recorded partial payment.',
      'refused' => 'Driver recorded that cash was refused.',
      'unpaid' => 'Driver recorded no cash received.',
      'disputed' => 'Outcome disputed. Report an issue if needed.',
      _ => 'Payment status unavailable.',
    };
  }
}
