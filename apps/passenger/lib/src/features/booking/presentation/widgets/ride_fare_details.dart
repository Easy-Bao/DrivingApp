import 'package:design_system/design_system.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_panel_header.dart';

class RideFareDetails extends StatelessWidget {
  const RideFareDetails({
    super.key,
    required this.passengerName,
    required this.fareResult,
    required this.offeredFare,
    required this.tipAmount,
    required this.totalFare,
    required this.onBackPressed,
  });
  final String passengerName;
  final FareEstimate fareResult;
  final double offeredFare;
  final int tipAmount;
  final double totalFare;
  final VoidCallback onBackPressed;

  double get _customOfferAdjustment {
    final adjustment = offeredFare - fareResult.totalFare;
    return adjustment > 0 ? adjustment : 0;
  }

  double get _surgeMultiplier {
    final subtotal =
        fareResult.baseFare + fareResult.distanceCharge + fareResult.timeCharge;
    if (subtotal <= 0) return 1.0;
    return (subtotal + fareResult.surgeCharge) / subtotal;
  }

  String _currency(double amount) => formatPesoAmount(amount);

  Widget _amountRow(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    final colors = context.colorScheme;
    final valueStyle =
        (emphasize
                ? context.textStyles.titleSmall
                : context.textStyles.bodyMedium)
            ?.tabular
            .copyWith(
              color: colors.onSurface,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: emphasize ? colors.onSurface : colors.onSurfaceVariant,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final hairline = colors.outlineVariant.withValues(alpha: 0.7);
    final normalizedPassengerName = passengerName.trim();
    return Padding(
      key: const ValueKey('fare-details'),
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RidePanelHeader(
            title: 'Fare details',
            details: 'How your total is calculated',
            onClose: onBackPressed,
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(height: 1, color: hairline),
          if (normalizedPassengerName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _amountRow(context, 'Passenger', normalizedPassengerName),
            const SizedBox(height: AppSpacing.xs),
            Divider(height: 1, color: hairline),
          ],
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              'FARE CALCULATION',
              style: context.textStyles.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _amountRow(context, 'Base fare', _currency(fareResult.baseFare)),
          _amountRow(context, 'Distance', _currency(fareResult.distanceCharge)),
          _amountRow(context, 'Time', _currency(fareResult.timeCharge)),
          if (fareResult.surgeCharge > 0)
            _amountRow(
              context,
              'Dynamic surge (${_surgeMultiplier.toStringAsFixed(1)}x)',
              _currency(fareResult.surgeCharge),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: hairline),
          ),
          _amountRow(
            context,
            'Calculated fare',
            _currency(fareResult.totalFare),
            emphasize: true,
          ),
          if (_customOfferAdjustment > 0)
            _amountRow(
              context,
              'Custom offer adjustment',
              '+${_currency(_customOfferAdjustment)}',
            ),
          _amountRow(
            context,
            'Tip',
            tipAmount == 0 ? 'No tip added' : _currency(tipAmount.toDouble()),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total fare',
                        style: context.textStyles.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pay your driver in cash',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _currency(totalFare),
                  style: context.textStyles.headlineSmall?.tabular.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
