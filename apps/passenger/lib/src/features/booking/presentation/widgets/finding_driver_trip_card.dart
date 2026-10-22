import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
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
    required IconData icon,
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
          child: Icon(icon, size: 18, color: colors.onSurface),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (details != null &&
                  details.isNotEmpty &&
                  details != value) ...[
                const SizedBox(height: 3),
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stop(
            context,
            icon: LucideIcons.map_pin,
            label: 'Pick up',
            value: pickup,
            details: pickupDetails,
            connectToNext: true,
          ),
          _stop(
            context,
            icon: LucideIcons.navigation,
            label: 'Drop off',
            value: destination,
            details: destinationDetails,
          ),
          if (dropoffMeta?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                dropoffMeta!,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
          Divider(
            height: 28,
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
          if (baseFare != null && tipAmount > 0) ...[
            Text(
              '${formatPesoAmount(baseFare!)} fare · ${formatPesoAmount(tipAmount.toDouble())} tip',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Total fare · Cash',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  formatPesoAmount(fare),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
