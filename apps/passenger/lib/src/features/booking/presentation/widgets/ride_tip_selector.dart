import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

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
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add a tip',
          style: context.textStyles.titleSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Optional, for excellent service.',
          style: context.textStyles.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
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
                        selectedColor: colors.primary,
                        backgroundColor: colors.surfaceContainerLowest,
                        side: BorderSide(
                          color: selectedTipAmount == amount
                              ? colors.primary
                              : colors.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        labelStyle: context.textStyles.titleSmall?.tabular
                            .copyWith(
                              color: selectedTipAmount == amount
                                  ? colors.onPrimary
                                  : colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
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
