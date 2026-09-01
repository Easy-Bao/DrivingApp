import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class const RideTipSelectorWidget({
  super.key,
  required this.selectedTipAmount,
  required this.onTipSelected,
}) extends StatelessWidget {
  static const tipOptions = [0, 10, 20, 30, 50, 100];

  final int selectedTipAmount;
  final ValueChanged<int> onTipSelected;

  String _labelFor(int amount) {
    return amount == 0 ? 'No tip' : '₱$amount';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add a tip',
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Optional, for excellent service.',
          style: TextStyle(
            color: context.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
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
                  selectedColor: context.colorScheme.onSurface,
                  backgroundColor: context.colorScheme.surface,
                  side: BorderSide(
                    color: selectedTipAmount == amount
                        ? context.colorScheme.onSurface
                        : context.colorScheme.outlineVariant,
                  ),
                  labelStyle: TextStyle(
                    color: selectedTipAmount == amount
                        ? context.colorScheme.surface
                        : context.colorScheme.onSurface,
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
