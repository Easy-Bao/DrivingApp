import 'package:flutter/material.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class RideOptionData {
  final String name;
  final String subtitle;
  final IconData icon;
  final double fare;
  final String eta;
  final String? badge;

  const RideOptionData({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.fare,
    required this.eta,
    this.badge,
  });
}

class RideOptionsPanelWidget extends StatelessWidget {
  final List<RideOptionData> options;
  final int selectedIndex;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onBookPressed;
  final TextEditingController customFareController;
  final double? minimumFare;
  final String? customFareError;
  final bool isLoadingFare;
  final String? fareError;
  final VoidCallback? onRetryFare;
  final ValueChanged<String> onCustomFareChanged;

  const RideOptionsPanelWidget({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onOptionSelected,
    required this.onBookPressed,
    required this.customFareController,
    required this.minimumFare,
    required this.customFareError,
    required this.isLoadingFare,
    required this.fareError,
    required this.onRetryFare,
    required this.onCustomFareChanged,
  });

  Widget _buildFareStatus() {
    if (isLoadingFare) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Calculating fare…'),
          ],
        ),
      );
    }

    final error = fareError;
    if (error != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        decoration: BoxDecoration(
          color: AppTheme.cancel.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cancel.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.cancel, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  color: AppTheme.cancel,
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ),
            TextButton(onPressed: onRetryFare, child: const Text('Try again')),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text('Fare details are unavailable.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = options.isEmpty
        ? null
        : options[selectedIndex < options.length ? selectedIndex : 0];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'SOLO RIDE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (options.isEmpty) _buildFareStatus(),
          ...List.generate(options.length, (index) {
            final option = options[index];
            final isSelected = index == selectedIndex;
            return GestureDetector(
              onTap: () => onOptionSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.05)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.borderSide,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.neutralColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        option.icon,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                option.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              if (option.badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: option.badge == 'Cheapest'
                                        ? AppTheme.complete.withValues(
                                            alpha: 0.15,
                                          )
                                        : AppTheme.tertiaryColor.withValues(
                                            alpha: 0.15,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    option.badge!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: option.badge == 'Cheapest'
                                          ? AppTheme.complete
                                          : AppTheme.tertiaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          minimumFare == null
                              ? 'Calculating...'
                              : '₱${(double.tryParse(customFareController.text) ?? option.fare).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '~${option.eta}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          if (selectedOption != null) ...[
            const SizedBox(height: 4),
            TextField(
              controller: customFareController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: onCustomFareChanged,
              decoration: InputDecoration(
                labelText: 'Your offer',
                prefixText: '₱ ',
                helperText:
                    'Custom offer cannot be lower than calculated minimum fare.',
                errorText: customFareError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.borderSide),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed:
                selectedOption == null ||
                    minimumFare == null ||
                    customFareError != null
                ? null
                : onBookPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: Text(
              selectedOption == null
                  ? isLoadingFare
                        ? 'Calculating fare…'
                        : 'Fare unavailable'
                  : 'Book ${selectedOption.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
