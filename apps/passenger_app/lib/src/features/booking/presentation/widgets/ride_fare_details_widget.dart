import 'package:passenger_app/src/features/booking/booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

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
              IconButton(
                onPressed: onBackPressed,
                tooltip: 'Back to trip summary',
                style: IconButton.styleFrom(shape: const CircleBorder()),
                icon: Icon(
                  LucideIcons.arrow_left,
                  color: context.colorScheme.onSurface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare details',
                      style: TextStyle(
                        color: context.colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
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
            const SizedBox(height: 12),
            _amountRow(context, 'Passenger', normalizedPassengerName),
          ],
          const Divider(height: 28),
          Text(
            'Fare Calculation',
            style: TextStyle(
              color: context.colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          _amountRow(context, 'Base fare', _currency(fareResult.baseFare)),
          _amountRow(context, 'Distance', _currency(fareResult.distanceCharge)),
          _amountRow(context, 'Time', _currency(fareResult.timeCharge)),
          if (fareResult.surgeCharge > 0)
            _amountRow(context, 'Surge', _currency(fareResult.surgeCharge)),
          const Divider(height: 24),
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
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total fare',
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _currency(totalFare),
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
