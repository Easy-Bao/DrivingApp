import 'package:flutter/material.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class RideTipSelectorWidget extends StatelessWidget {
  static const tipOptions = [0, 10, 20, 30, 50, 100];

  final int selectedTipAmount;
  final ValueChanged<int> onTipSelected;

  const RideTipSelectorWidget({
    super.key,
    required this.selectedTipAmount,
    required this.onTipSelected,
  });

  String _labelFor(int amount) {
    return amount == 0 ? 'No tip' : '₱$amount';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add a tip',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Optional, for excellent service.',
          style: TextStyle(color: AppTheme.tertiaryColor, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final amount in tipOptions) ...[
                ChoiceChip(
                  label: Text(_labelFor(amount)),
                  selected: selectedTipAmount == amount,
                  onSelected: (_) => onTipSelected(amount),
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: AppTheme.surface,
                  side: BorderSide(
                    color: selectedTipAmount == amount
                        ? AppTheme.primaryColor
                        : AppTheme.borderSide,
                  ),
                  labelStyle: TextStyle(
                    color: selectedTipAmount == amount
                        ? Colors.white
                        : AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                if (amount != tipOptions.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
