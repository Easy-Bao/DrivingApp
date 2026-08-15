import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_fare_details_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_tip_selector_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_trip_summary_widget.dart';

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
  final String rideTypeLabel;
  final String pickupLabel;
  final String destinationName;
  final String destinationAddress;
  final String distance;
  final String duration;
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
  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;
  final int selectedTipAmount;
  final ValueChanged<int> onTipSelected;
  final double totalFare;
  final bool isShowingFareDetails;
  final VoidCallback onShowFareDetails;
  final VoidCallback onHideFareDetails;

  const RideOptionsPanelWidget({
    super.key,
    required this.rideTypeLabel,
    required this.pickupLabel,
    required this.destinationName,
    required this.destinationAddress,
    required this.distance,
    required this.duration,
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
    required this.notesController,
    required this.onNotesChanged,
    required this.selectedTipAmount,
    required this.onTipSelected,
    required this.totalFare,
    required this.isShowingFareDetails,
    required this.onShowFareDetails,
    required this.onHideFareDetails,
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

  Widget _buildRideOption(RideOptionData option, int index) {
    final isSelected = index == selectedIndex;
    final fare = double.tryParse(customFareController.text) ?? option.fare;
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
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderSide,
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
                color: isSelected ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          option.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
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
                                ? AppTheme.complete.withValues(alpha: 0.15)
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  minimumFare == null
                      ? 'Calculating...'
                      : '₱${fare.toStringAsFixed(2)}',
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
  }

  Widget _buildTotalFareCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: totalFare > 0 ? onShowFareDetails : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          key: const ValueKey('fare-summary'),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.neutralColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderSide),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.receipt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total fare',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap to view full fare details',
                      style: TextStyle(
                        color: AppTheme.tertiaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${totalFare.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFareSummary({required RideOptionData selectedOption}) {
    final baseFare =
        double.tryParse(customFareController.text) ?? selectedOption.fare;
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) => ClipRect(
          child: Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              ...previousChildren,
              currentChild ?? const SizedBox.shrink(),
            ],
          ),
        ),
        transitionBuilder: (child, animation) {
          final isDetails = child.key == const ValueKey('fare-details');
          final isEnteringDetails = isShowingFareDetails && isDetails;
          final beginOffset =
              isEnteringDetails || (!isShowingFareDetails && !isDetails)
              ? const Offset(1, 0)
              : const Offset(-1, 0);
          return SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: isShowingFareDetails
            ? RideFareDetailsWidget(
                passengerLabel: 'You',
                pickupLabel: pickupLabel,
                destinationName: destinationName,
                destinationAddress: destinationAddress,
                distance: distance,
                duration: duration,
                baseFare: baseFare,
                tipAmount: selectedTipAmount,
                totalFare: totalFare,
                notes: notesController.text.trim(),
                onBackPressed: onHideFareDetails,
              )
            : _buildTotalFareCard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = options.isEmpty
        ? null
        : options[selectedIndex < options.length ? selectedIndex : 0];
    final canBook =
        selectedOption != null &&
        minimumFare != null &&
        customFareError == null;

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
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
            Text(
              rideTypeLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            RideTripSummaryWidget(
              pickupLabel: pickupLabel,
              destinationName: destinationName,
              destinationAddress: destinationAddress,
              distance: distance,
              duration: duration,
            ),
            const SizedBox(height: 12),
            if (options.isEmpty) _buildFareStatus(),
            for (var index = 0; index < options.length; index++)
              _buildRideOption(options[index], index),
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
              const SizedBox(height: 12),
              RideTipSelectorWidget(
                selectedTipAmount: selectedTipAmount,
                onTipSelected: onTipSelected,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                maxLength: 160,
                onChanged: onNotesChanged,
                decoration: InputDecoration(
                  labelText: 'Notes for the driver (optional)',
                  hintText: 'Add a pickup note',
                  prefixIcon: const Icon(LucideIcons.file_text, size: 18),
                  counterText: '',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.borderSide),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildFareSummary(selectedOption: selectedOption),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: isShowingFareDetails
                  ? onHideFareDetails
                  : canBook
                  ? onBookPressed
                  : null,
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
                    : isShowingFareDetails
                    ? 'Back to fare summary'
                    : 'Book ${selectedOption.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
