import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';

Future<void> showHomeActiveRideBlockedDialog(
  BuildContext context, {
  required String driverName,
  required VoidCallback onResumeTrip,
}) {
  return _showHomeNoticeDialog(
    context,
    icon: LucideIcons.car,
    title: 'Active Ride in Progress',
    content:
        'You already have an active trip with $driverName. Please complete or cancel your ongoing ride before booking another.',
    primaryLabel: 'Resume Trip',
    onPrimaryAction: onResumeTrip,
  );
}

Future<void> showHomeActiveBookingBlockedDialog(
  BuildContext context, {
  required BookingState bookingState,
  required ActiveDriverSearch? activeSearch,
  required VoidCallback onRetryRecovery,
  required ValueChanged<String?> onResumeMatchedRide,
  required ValueChanged<ActiveDriverSearch> onOpenActiveSearch,
}) {
  final isMatchedOrRecovered =
      bookingState is BookingDriverMatched ||
      bookingState is BookingRideRecovered;
  final isRecoveryFailure = bookingState is BookingSessionRecoveryFailure;
  final isRecovering = bookingState is BookingSessionRecoveryInProgress;

  final String title;
  final String content;
  final IconData icon;
  final String? primaryLabel;
  VoidCallback? primaryAction;

  if (isMatchedOrRecovered) {
    title = 'Driver Accepted Your Trip';
    content = 'Your driver has already accepted your ride. Please resume or complete your ongoing trip before booking another.';
    icon = LucideIcons.car;
    primaryLabel = 'Resume Trip';
    final matchedRideId = switch (bookingState) {
      BookingDriverMatched(:final rideId) => rideId,
      BookingRideRecovered(:final rideId) => rideId,
      _ => null,
    };
    primaryAction = () => onResumeMatchedRide(matchedRideId);
  } else if (isRecoveryFailure) {
    title = 'Booking Request in Progress';
    content = 'We are still confirming your active ride request. Retry checking its status before booking another.';
    icon = LucideIcons.circle_alert;
    primaryLabel = 'Retry';
    primaryAction = onRetryRecovery;
  } else if (isRecovering) {
    title = 'Booking Request in Progress';
    content = 'We are checking your current ride request. Please wait a moment before booking another.';
    icon = LucideIcons.clock;
    primaryLabel = activeSearch != null ? 'View Request' : null;
    primaryAction = activeSearch == null
        ? null
        : () => onOpenActiveSearch(activeSearch);
  } else if (bookingState is BookingFindingNearbyDrivers) {
    final destinationName =
        activeSearch?.trip.destination.name.trim() ??
        bookingState.trip.destination.name.trim();
    title = 'Driver Search in Progress';
    content = destinationName.isNotEmpty
        ? 'You are already looking for a driver to $destinationName. View or cancel it before starting another booking.'
        : 'You are already looking for a driver. View or cancel your current search before starting another booking.';
    icon = LucideIcons.clock;
    primaryLabel = activeSearch != null ? 'View Search' : null;
    primaryAction = activeSearch == null
        ? null
        : () => onOpenActiveSearch(activeSearch);
  } else {
    final destinationName = activeSearch?.trip.destination.name.trim() ?? '';
    title = 'Booking Request in Progress';
    content = destinationName.isNotEmpty
        ? 'You already have a ride request to $destinationName waiting for a driver. View or cancel it before booking another.'
        : 'You already have a ride request waiting for a driver. Please wait for a response or cancel it before booking another.';
    icon = LucideIcons.clock;
    primaryLabel = activeSearch != null ? 'View Request' : null;
    primaryAction = activeSearch == null
        ? null
        : () => onOpenActiveSearch(activeSearch);
  }

  return _showHomeNoticeDialog(
    context,
    icon: icon,
    isErrorIcon: isRecoveryFailure,
    title: title,
    content: content,
    primaryLabel: primaryLabel,
    onPrimaryAction: primaryAction,
  );
}

Future<void> _showHomeNoticeDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String content,
  bool isErrorIcon = false,
  String? primaryLabel,
  VoidCallback? onPrimaryAction,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.colorScheme;
      return AlertDialog(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: colors.outlineVariant),
        ),
        icon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: colors.outlineVariant),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: isErrorIcon ? colors.error : colors.onSurface,
          ),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: dialogContext.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: Text(
          content,
          textAlign: TextAlign.center,
          style: dialogContext.textStyles.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style:
                TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.focused)
                        ? colors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                ),
            child: const Text('Dismiss'),
          ),
          if (primaryLabel != null && onPrimaryAction != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onPrimaryAction();
              },
              style:
                  FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    elevation: 0,
                    enableFeedback: false,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.focused)
                          ? colors.onPrimary.withValues(alpha: 0.16)
                          : Colors.transparent,
                    ),
                  ),
              child: Text(primaryLabel),
            ),
        ],
      );
    },
  );
}

Future<void> showSavedPlaceChipOptionsSheet(
  BuildContext context, {
  required String label,
  required Future<void> Function() onRemove,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colors = sheetContext.colorScheme;
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.pagePadding,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sheetContext.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.7),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.focused)
                        ? colors.error.withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await onRemove();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLayout.pagePadding,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.trash_2,
                            color: colors.error,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Remove shortcut',
                          style: sheetContext.textStyles.bodyLarge?.copyWith(
                            color: colors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
    },
  );
}
