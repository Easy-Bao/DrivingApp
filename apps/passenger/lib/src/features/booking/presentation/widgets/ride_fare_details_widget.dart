import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/booking.dart';

class const RideFareDetailsWidget({
  super.key,
  required this.passengerName,
  required this.fareResult,
  required this.offeredFare,
  required this.tipAmount,
  required this.totalFare,
  required this.onBackPressed,
}) extends StatelessWidget {
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

  String _currency(double amount) => formatPesoAmount(amount);

  Widget _amountRow(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    final valueStyle = TextStyle(
      color: context.colorScheme.onSurface,
      fontSize: emphasize ? 14 : 13,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
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
                fontSize: 13,
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
          Row(
            children: [
              Tooltip(
                message: 'Back to trip summary',
                child: InkWell(
                  onTap: onBackPressed,
                  borderRadius: BorderRadius.circular(EasyRideRadius.pill),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: context.colorScheme.outlineVariant,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.arrow_left,
                      color: context.colorScheme.onSurface,
                      size: 19,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare details',
                      style: TextStyle(
                        color: context.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'How your total is calculated',
                      style: TextStyle(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (normalizedPassengerName.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(EasyRideRadius.md),
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
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(EasyRideRadius.lg),
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
                    'Surge',
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
              borderRadius: BorderRadius.circular(EasyRideRadius.lg),
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
                        'Transparent pricing · No hidden fees',
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
