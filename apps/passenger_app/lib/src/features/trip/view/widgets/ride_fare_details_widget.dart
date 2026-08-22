import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:shared_core/shared_core.dart';

class RideFareDetailsWidget extends StatelessWidget {
  final String passengerName;
  final FareResult fareResult;
  final double offeredFare;
  final int tipAmount;
  final double totalFare;
  final VoidCallback onBackPressed;

  const RideFareDetailsWidget({
    super.key,
    required this.passengerName,
    required this.fareResult,
    required this.offeredFare,
    required this.tipAmount,
    required this.totalFare,
    required this.onBackPressed,
  });

  double get _customOfferAdjustment {
    final adjustment = offeredFare - fareResult.totalFare;
    return adjustment > 0 ? adjustment : 0;
  }

  String _currency(double amount) => '₱${amount.toStringAsFixed(2)}';

  Widget _amountRow(String label, String value, {bool emphasize = false}) {
    final valueStyle = TextStyle(
      color: AppTheme.primaryColor,
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
                color: AppTheme.primaryColor.withValues(alpha: 0.58),
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
                icon: const Icon(
                  LucideIcons.arrow_left,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare details',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'How your total is calculated',
                      style: TextStyle(
                        color: AppTheme.tertiaryColor,
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
            _amountRow('Passenger', normalizedPassengerName),
          ],
          const Divider(height: 28),
          Text(
            'Fare Calculation',
            style: TextStyle(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          _amountRow('Base fare', _currency(fareResult.baseFare)),
          _amountRow('Distance', _currency(fareResult.distanceCharge)),
          _amountRow('Time', _currency(fareResult.timeCharge)),
          if (fareResult.surgeCharge > 0)
            _amountRow('Surge', _currency(fareResult.surgeCharge)),
          const Divider(height: 24),
          _amountRow(
            'Calculated fare',
            _currency(fareResult.totalFare),
            emphasize: true,
          ),
          if (_customOfferAdjustment > 0)
            _amountRow(
              'Custom offer adjustment',
              '+${_currency(_customOfferAdjustment)}',
            ),
          _amountRow(
            'Tip',
            tipAmount == 0 ? 'No tip added' : _currency(tipAmount.toDouble()),
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total fare',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _currency(totalFare),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
