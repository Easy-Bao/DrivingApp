import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_trip_card.dart';

class FindingDriverStatusSheet extends StatelessWidget {
  const FindingDriverStatusSheet({
    super.key,
    required this.title,
    required this.message,
    required this.statusIcon,
    required this.statusColor,
    required this.destination,
    this.pickupAddress,

    required this.fare,
    required this.onCancelPressed,
    this.primaryAction,
    this.primaryActionLabel,
    this.cancelLabel = 'Cancel search',
    this.isCanceling = false,
  });

  final String title;
  final String message;
  final IconData statusIcon;
  final Color statusColor;
  final String destination;
  final String? pickupAddress;

  final double fare;
  final VoidCallback onCancelPressed;
  final VoidCallback? primaryAction;
  final String? primaryActionLabel;
  final String cancelLabel;
  final bool isCanceling;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Material(
      key: const ValueKey('finding-driver-status-sheet'),
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      shadowColor: colors.onSurface.withValues(alpha: 0.12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 22),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                FindingDriverTripCard(
                  key: const ValueKey('finding-driver-trip-context'),
                  pickup: pickupAddress?.trim().isNotEmpty == true
                      ? pickupAddress!.trim()
                      : 'Current location',
                  destination: destination,
                  fare: fare,
                ),
                const SizedBox(height: 20),
                if (primaryAction != null && primaryActionLabel != null)
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: isCanceling ? null : primaryAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.onSurface,
                        foregroundColor: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(primaryActionLabel!),
                    ),
                  ),
                TextButton(
                  onPressed: isCanceling ? null : onCancelPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: isCanceling
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onSurface,
                          ),
                        )
                      : Text(cancelLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
