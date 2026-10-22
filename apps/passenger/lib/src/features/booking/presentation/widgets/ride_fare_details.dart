import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
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
    final valueStyle = TextStyle(
      color: context.colorScheme.onSurface,
      fontSize: emphasize ? 16 : 14,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
          if (normalizedPassengerName.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              child: _amountRow(context, 'Passenger', normalizedPassengerName),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FARE CALCULATION',
                  style: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                _amountRow(
                  context,
                  'Base fare',
                  _currency(fareResult.baseFare),
                ),
                _amountRow(
                  context,
                  'Distance',
                  _currency(fareResult.distanceCharge),
                ),
                _amountRow(context, 'Time', _currency(fareResult.timeCharge)),
                if (fareResult.surgeCharge > 0)
                  _amountRow(
                    context,
                    'Dynamic surge (${_surgeMultiplier.toStringAsFixed(1)}x)',
                    _currency(fareResult.surgeCharge),
                  ),
                Divider(
                  height: 20,
                  color: context.colorScheme.outlineVariant,
                  thickness: 0.8,
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
                  tipAmount == 0
                      ? 'No tip added'
                      : _currency(tipAmount.toDouble()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: context.colorScheme.outlineVariant,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total fare',
                        style: TextStyle(
                          color: context.colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pay your driver in cash',
                        style: TextStyle(
                          color: context.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _currency(totalFare),
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
