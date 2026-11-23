import 'package:design_system/design_system.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_route_connector.dart';

class FindingDriverTripCard extends StatelessWidget {
  const FindingDriverTripCard({
    super.key,
    required this.pickup,
    required this.destination,
    required this.fare,
    this.pickupDetails,
    this.destinationDetails,
    this.dropoffMeta,
    this.baseFare,
    this.tipAmount = 0,
  });

  final String pickup;
  final String destination;
  final double fare;
  final String? pickupDetails;
  final String? destinationDetails;
  final String? dropoffMeta;
  final double? baseFare;
  final int tipAmount;

  Widget _stop(
    BuildContext context, {
    required bool isPickup,
    required String label,
    required String value,
    String? details,
    bool connectToNext = false,
  }) {
    final colors = context.colorScheme;
    final stop = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: RouteStopMarker(isPickup: isPickup, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (details != null &&
                  details.isNotEmpty &&
                  details != value) ...[
                const SizedBox(height: 2),
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    if (!connectToNext) return stop;
    return Stack(
      children: [
        Positioned(
          left: 8,
          top: 24,
          bottom: 0,
          width: 2,
          child: FindingDriverRouteConnector(color: colors.outlineVariant),
        ),
        Padding(padding: const EdgeInsets.only(bottom: 14), child: stop),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final hairline = colors.outlineVariant.withValues(alpha: 0.7);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stop(
            context,
            isPickup: true,
            label: 'Pick up',
            value: pickup,
            details: pickupDetails,
            connectToNext: true,
          ),
          _stop(
            context,
            isPickup: false,
            label: 'Drop off',
            value: destination,
            details: destinationDetails,
          ),
          if (dropoffMeta?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                dropoffMeta!,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
          Divider(height: 28, color: hairline),
          if (baseFare != null && tipAmount > 0) ...[
            Text(
              '${formatPesoAmount(baseFare!)} fare · ${formatPesoAmount(tipAmount.toDouble())} tip',
              style: context.textStyles.bodySmall?.tabular.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Total fare · Cash',
                  style: context.textStyles.bodySmall?.copyWith(
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
      ),
    );
  }
}
