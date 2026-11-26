import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_panel_header.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_tip_selector.dart';

ButtonStyle rideOptionsPrimaryButtonStyle(BuildContext context) {
  final colors = context.colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: colors.primary,
    foregroundColor: colors.onPrimary,
    disabledBackgroundColor: colors.surfaceContainerHighest,
    disabledForegroundColor: colors.onSurfaceVariant.withValues(alpha: 0.45),
    elevation: 0,
    enableFeedback: false,
    splashFactory: NoSplash.splashFactory,
    minimumSize: const Size.fromHeight(AppSize.controlHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    textStyle: context.textStyles.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused)
          ? colors.onPrimary.withValues(alpha: 0.16)
          : Colors.transparent,
    ),
  );
}

class RideOfferSubView extends StatelessWidget {
  const RideOfferSubView({
    super.key,
    required this.minimumFare,
    required this.enteredFare,
    required this.hasValidFare,
    required this.customFareController,
    required this.customFareError,
    required this.onCustomFareChanged,
    required this.onBackToSummary,
  });

  final double minimumFare;
  final double? enteredFare;
  final bool hasValidFare;
  final TextEditingController customFareController;
  final String? customFareError;
  final ValueChanged<String> onCustomFareChanged;
  final VoidCallback onBackToSummary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RidePanelHeader(
          closeKey: const ValueKey('panel-back'),
          onClose: onBackToSummary,
          title: 'Set your offer',
          details: 'Match or raise the calculated fare.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculated minimum',
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      formatPesoAmount(minimumFare),
                      style: context.textStyles.headlineSmall?.tabular.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text(
                      'Minimum',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your offer',
                key: const ValueKey('custom-offer-label'),
                style: context.textStyles.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const ValueKey('custom-offer-input'),
                controller: customFareController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                textInputAction: TextInputAction.done,
                onChanged: onCustomFareChanged,
                onSubmitted: (_) {
                  if (hasValidFare) onBackToSummary();
                },
                style: context.textStyles.headlineMedium?.tabular.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  hintText: '0.00',
                  helperText: customFareError == null
                      ? 'Match or raise the calculated fare.'
                      : null,
                  helperMaxLines: 2,
                  errorText: customFareError,
                  errorMaxLines: 3,
                  errorStyle: context.textStyles.bodySmall?.copyWith(
                    color: colors.error,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Theme(
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
                    for (final increment in const [10, 20, 50])
                      ActionChip(
                        elevation: 0,
                        pressElevation: 0,
                        backgroundColor: colors.surfaceContainerLowest,
                        side: BorderSide(color: colors.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        label: Text(
                          '+₱$increment',
                          style: context.textStyles.labelMedium?.tabular
                              .copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onPressed: () {
                          final current = enteredFare ?? minimumFare;
                          customFareController.text = (current + increment)
                              .toStringAsFixed(2);
                          onCustomFareChanged(customFareController.text);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('custom-offer-save'),
            onPressed: hasValidFare ? onBackToSummary : null,
            style: rideOptionsPrimaryButtonStyle(context),
            child: const Text('Save offer'),
          ),
        ),
      ],
    );
  }
}

class RideTipSubView extends StatelessWidget {
  const RideTipSubView({
    super.key,
    required this.selectedTipAmount,
    required this.onTipSelected,
    required this.onBackToSummary,
  });

  final int selectedTipAmount;
  final ValueChanged<int> onTipSelected;
  final VoidCallback onBackToSummary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RidePanelHeader(
          closeKey: const ValueKey('panel-back'),
          onClose: onBackToSummary,
          title: 'Tip your driver',
          details: '100% of your tip goes directly to the driver.',
        ),
        const SizedBox(height: AppSpacing.lg),
        RideTipSelector(
          selectedTipAmount: selectedTipAmount,
          onTipSelected: onTipSelected,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('tip-save-button'),
            onPressed: onBackToSummary,
            style: rideOptionsPrimaryButtonStyle(context),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class RideNoteSubView extends StatelessWidget {
  const RideNoteSubView({
    super.key,
    required this.notesController,
    required this.onNotesChanged,
    required this.onBackToSummary,
  });

  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onBackToSummary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RidePanelHeader(
          closeKey: const ValueKey('panel-back'),
          onClose: onBackToSummary,
          title: 'Add a trip note',
          details: 'Help your driver find you quickly.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.file_text,
                    size: 17,
                    color: colors.onSurface,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Pickup note',
                    style: context.textStyles.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Optional · visible to your driver before pickup.',
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('trip-note-input'),
                controller: notesController,
                minLines: 3,
                maxLines: 5,
                maxLength: 160,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                inputFormatters: [LengthLimitingTextInputFormatter(160)],
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onChanged: onNotesChanged,
                decoration: InputDecoration(
                  hintText: 'For example: Meet me at the side entrance.',
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  alignLabelWithHint: true,
                  counterStyle: context.textStyles.labelSmall?.tabular.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Theme(
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
                    for (final preset in const [
                      'Wait at lobby',
                      'Near entrance',
                      'Have luggage',
                      'Call on arrival',
                    ])
                      ActionChip(
                        elevation: 0,
                        pressElevation: 0,
                        backgroundColor: colors.surfaceContainerLowest,
                        side: BorderSide(color: colors.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        label: Text(
                          preset,
                          style: context.textStyles.labelMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onPressed: () {
                          final current = notesController.text.trim();
                          final next = current.isEmpty
                              ? preset
                              : current.contains(preset)
                              ? current
                              : '$current. $preset';
                          final clamped = next.length > 160
                              ? next.substring(0, 160)
                              : next;
                          notesController.text = clamped;
                          onNotesChanged(notesController.text);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('trip-note-save'),
            onPressed: onBackToSummary,
            style: rideOptionsPrimaryButtonStyle(context),
            child: const Text('Save note'),
          ),
        ),
      ],
    );
  }
}

class RideSummaryTripCard extends StatelessWidget {
  const RideSummaryTripCard({
    super.key,
    required this.pickupLabel,
    required this.destinationName,
  });

  final String pickupLabel;
  final String destinationName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      key: const ValueKey('trip-summary-card'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Column(
            children: [
              const RouteStopMarker(isPickup: true, size: 18),
              CustomPaint(
                size: const Size(2, 22),
                painter: _DottedLinePainter(color: colors.outlineVariant),
              ),
              const RouteStopMarker(isPickup: false, size: 18),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick up',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  pickupLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Drop off',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RideFareStatusCard extends StatelessWidget {
  const RideFareStatusCard({
    super.key,
    required this.error,
    required this.onRetryFare,
  });

  final String error;
  final VoidCallback? onRetryFare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.circle_alert, color: colors.error, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  error,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.error,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (onRetryFare != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetryFare,
                style:
                    TextButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? colors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                    ),
                child: const Text('Try again'),
              ),
            ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    var startY = 3.0;
    while (startY < size.height - 3.0) {
      canvas.drawCircle(Offset(size.width / 2, startY), 1.0, paint);
      startY += 5.0;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
