import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class TripCancellationDialog extends StatefulWidget {
  const TripCancellationDialog({super.key});

  static const Map<String, String> cancellationReasons = {
    'passenger_changed_mind': 'Changed my mind',
    'driver_taking_too_long': 'Driver is taking too long',
    'found_another_ride': 'Found another ride',
    'wrong_pickup_location': 'Wrong pickup location',
    'driver_asked_to_cancel': 'Driver asked to cancel',
    'driver_no_show': 'Driver did not arrive',
  };

  @override
  State<TripCancellationDialog> createState() => _TripCancellationDialogState();
}

class _TripCancellationDialogState extends State<TripCancellationDialog> {
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return AppBottomSheetContainer(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm + 2,
        AppSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancel ride?',
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose the reason that best describes what happened.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSelectField<String>.anchored(
              key: const ValueKey('cancellation-reason-dropdown'),
              value: _selectedReason,
              menuTitle: 'Reason for cancellation',
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'Select a reason',
              ),
              options: [
                for (final entry
                    in TripCancellationDialog.cancellationReasons.entries)
                  AppSelectOption<String>(value: entry.key, label: entry.value),
              ],
              onChanged: (value) => setState(() => _selectedReason = value),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Select a reason so EasyRide can record what happened. No cancellation fee is collected in the app.',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style:
                        OutlinedButton.styleFrom(
                          backgroundColor: colors.surfaceContainerLowest,
                          foregroundColor: colors.onSurface,
                          side: BorderSide(color: colors.outlineVariant),
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size.fromHeight(
                            AppSize.controlHeight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          textStyle: context.textStyles.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? colors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                        ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Keep ride'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('confirm-cancel-ride-button'),
                    style:
                        FilledButton.styleFrom(
                          backgroundColor: colors.error,
                          foregroundColor: colors.onError,
                          disabledBackgroundColor:
                              colors.surfaceContainerHighest,
                          disabledForegroundColor: colors.onSurfaceVariant
                              .withValues(alpha: 0.38),
                          elevation: 0,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size.fromHeight(
                            AppSize.controlHeight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          textStyle: context.textStyles.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? colors.onError.withValues(alpha: 0.16)
                                : Colors.transparent,
                          ),
                        ),
                    onPressed: _selectedReason == null
                        ? null
                        : () => Navigator.pop(context, _selectedReason),
                    child: const Text('Cancel ride'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> showTripCancellationSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (_) => const TripCancellationDialog(),
  );
}
