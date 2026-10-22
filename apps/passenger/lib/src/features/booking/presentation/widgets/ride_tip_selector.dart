import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class const RideTipSelector({
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
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 280 ? 2 : 3;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final amount in tipOptions)
                    SizedBox(
                      width: width,
                      child: ChoiceChip(
                        elevation: 0,
                        pressElevation: 0,
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            _labelFor(amount),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        selected: selectedTipAmount == amount,
                        onSelected: (_) => onTipSelected(amount),
                        selectedColor: context.colorScheme.onSurface,
                        backgroundColor: context.colorScheme.surface,
                        side: BorderSide(
                          color: selectedTipAmount == amount
                              ? context.colorScheme.onSurface
                              : context.colorScheme.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        labelStyle: TextStyle(
                          color: selectedTipAmount == amount
                              ? context.colorScheme.surface
                              : context.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
