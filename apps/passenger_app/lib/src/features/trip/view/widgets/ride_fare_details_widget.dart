import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class RideFareDetailsWidget extends StatelessWidget {
  final String passengerLabel;
  final String pickupLabel;
  final String destinationName;
  final String destinationAddress;
  final String distance;
  final String duration;
  final double baseFare;
  final int tipAmount;
  final double totalFare;
  final String notes;
  final VoidCallback onBackPressed;

  const RideFareDetailsWidget({
    super.key,
    required this.passengerLabel,
    required this.pickupLabel,
    required this.destinationName,
    required this.destinationAddress,
    required this.distance,
    required this.duration,
    required this.baseFare,
    required this.tipAmount,
    required this.totalFare,
    required this.notes,
    required this.onBackPressed,
  });

  String _currency(double amount) => '₱${amount.toStringAsFixed(2)}';

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryColor.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('fare-details'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBackPressed,
                tooltip: 'Back to fare summary',
                visualDensity: VisualDensity.compact,
                icon: const Icon(LucideIcons.arrow_left, size: 18),
              ),
              const SizedBox(width: 2),
              const Text(
                'Fare details',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          _detailRow('Passenger', passengerLabel),
          _detailRow('Pickup', pickupLabel),
          _detailRow(
            'Destination',
            destinationAddress.isEmpty
                ? destinationName
                : '$destinationName · $destinationAddress',
          ),
          if (distance.isNotEmpty) _detailRow('Distance', distance),
          if (duration.isNotEmpty) _detailRow('Estimated time', duration),
          const SizedBox(height: 4),
          const Divider(height: 12),
          _detailRow('Ride fare', _currency(baseFare)),
          _detailRow(
            'Tip',
            tipAmount == 0 ? 'Not now' : _currency(tipAmount.toDouble()),
          ),
          if (notes.isNotEmpty) _detailRow('Notes', notes),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total fare',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _currency(totalFare),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 18,
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
