import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const RideConfirmationSlider({
  super.key,
  required this.progress,
  required this.label,
  required this.releaseLabel,
  required this.processingLabel,
  required this.hint,
  required this.isProcessing,
  required this.onProgressChanged,
  required this.onConfirmed,
}) extends StatefulWidget {
  static const double thumbSize = 52;
  static const double confirmationThreshold = 0.85;

  final double progress;
  final String label;
  final String releaseLabel;
  final String processingLabel;
  final String hint;
  final bool isProcessing;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onConfirmed;

  @override
  State<RideConfirmationSlider> createState() => _RideConfirmationSliderState();
}

class _RideConfirmationSliderState extends State<RideConfirmationSlider> {
  double? _dragProgress;

  @override
  Widget build(BuildContext context) {
    final progress = (_dragProgress ?? widget.progress)
        .clamp(0.0, 1.0)
        .toDouble();

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel =
              (constraints.maxWidth - RideConfirmationSlider.thumbSize)
                  .clamp(0.0, double.infinity)
                  .toDouble();
          final canInteract = !widget.isProcessing && travel > 0;
          final colors = context.colorScheme;
          final fillWidth =
              RideConfirmationSlider.thumbSize + travel * progress;

          return Container(
            key: const ValueKey<String>('ride-confirmation-slider'),
            height: RideConfirmationSlider.thumbSize,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.85),
              ),
            ),
            child: Stack(
              children: [
                if (progress > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: fillWidth,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RideConfirmationSlider.thumbSize + 8,
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        widget.isProcessing
                            ? widget.processingLabel
                            : progress > 0.8
                            ? widget.releaseLabel
                            : widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: context.textStyles.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: travel * progress,
                  top: 0,
                  child: Semantics(
                    slider: true,
                    label: widget.label,
                    value: widget.isProcessing
                        ? widget.processingLabel
                        : '${(progress * 100).round()} percent',
                    increasedValue: canInteract
                        ? '${((progress + 0.1).clamp(0.0, 1.0) * 100).round()} percent'
                        : null,
                    decreasedValue: canInteract
                        ? '${((progress - 0.1).clamp(0.0, 1.0) * 100).round()} percent'
                        : null,
                    hint: widget.hint,
                    enabled: canInteract,
                    onIncrease: canInteract
                        ? () {
                            final nextProgress = (progress + 0.1)
                                .clamp(0.0, 1.0)
                                .toDouble();
                            widget.onProgressChanged(nextProgress);
                            if (nextProgress >=
                                RideConfirmationSlider.confirmationThreshold) {
                              widget.onConfirmed();
                            }
                          }
                        : null,
                    onDecrease: canInteract
                        ? () => widget.onProgressChanged(
                            (progress - 0.1).clamp(0.0, 1.0).toDouble(),
                          )
                        : null,
                    child: GestureDetector(
                      onHorizontalDragStart: canInteract
                          ? (_) => _dragProgress = progress
                          : null,
                      onHorizontalDragUpdate: canInteract
                          ? (details) {
                              final nextProgress =
                                  ((_dragProgress ?? progress) +
                                          details.delta.dx / travel)
                                      .clamp(0.0, 1.0)
                                      .toDouble();
                              setState(() => _dragProgress = nextProgress);
                              widget.onProgressChanged(nextProgress);
                            }
                          : null,
                      onHorizontalDragEnd: canInteract
                          ? (_) {
                              final finalProgress = _dragProgress ?? progress;
                              setState(() => _dragProgress = null);
                              if (finalProgress >=
                                  RideConfirmationSlider
                                      .confirmationThreshold) {
                                widget.onConfirmed();
                              } else {
                                widget.onProgressChanged(0);
                              }
                            }
                          : null,
                      onHorizontalDragCancel: canInteract
                          ? () {
                              setState(() => _dragProgress = null);
                              widget.onProgressChanged(0);
                            }
                          : null,
                      child: Container(
                        width: RideConfirmationSlider.thumbSize,
                        height: RideConfirmationSlider.thumbSize,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: widget.isProcessing
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : Icon(
                                  LucideIcons.chevron_right,
                                  color: colors.onPrimary,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
