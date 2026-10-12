import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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
          final colors = context.semanticColors;

          return Container(
            key: const ValueKey<String>('ride-confirmation-slider'),
            height: RideConfirmationSlider.thumbSize,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(EasyRideRadius.lg),
            ),
            child: Stack(
              children: [
                Center(
                  child: ExcludeSemantics(
                    child: Text(
                      widget.isProcessing
                          ? widget.processingLabel
                          : progress > 0.8
                          ? widget.releaseLabel
                          : widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.success,
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
                          color: colors.success,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: widget.isProcessing
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onSuccess,
                                  ),
                                )
                              : Icon(
                                  LucideIcons.chevron_right,
                                  color: colors.onSuccess,
                                  size: 22,
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
