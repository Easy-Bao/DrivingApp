import 'package:flutter/material.dart';

/// Draws one scaled active capsule per tab according to a continuous page
/// position.
///
/// The active tab owns the full capsule at an exact page position. During a
/// swipe, each participating capsule keeps its tab allocation, fades with its
/// allocation, and scales from its center. This keeps the indicator in the
/// same coordinate space as the page being dragged without resizing the
/// navigation slots.
class SwipeActiveTabIndicator extends StatelessWidget {
  static const defaultHorizontalInset = 3.0;
  static const defaultVerticalInset = 3.0;
  static const minimumScale = 0.35;

  final double pagePosition;
  final int itemCount;
  final Color color;
  final BorderRadius borderRadius;
  final double horizontalInset;
  final double verticalInset;
  final String? capsuleKeyPrefix;

  const SwipeActiveTabIndicator({
    super.key,
    required this.pagePosition,
    required this.itemCount,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(27)),
    this.horizontalInset = defaultHorizontalInset,
    this.verticalInset = defaultVerticalInset,
    this.capsuleKeyPrefix,
  }) : assert(itemCount > 0);

  /// Returns how much a tab participates in the active page allocation.
  ///
  /// Adjacent tabs share the allocation linearly while the page is between
  /// them. Tabs farther away remain collapsed at their center.
  static double selectionProgress(double pagePosition, int index) {
    final safePagePosition = pagePosition.isFinite ? pagePosition : 0.0;
    final progress = 1 - (safePagePosition - index).abs();
    return progress.clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final destinationWidth = constraints.maxWidth / itemCount;
        final safePagePosition = pagePosition.isFinite ? pagePosition : 0.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            for (var index = 0; index < itemCount; index++)
              _buildCapsule(destinationWidth, safePagePosition, index),
          ],
        );
      },
    );
  }

  Widget _buildCapsule(
    double destinationWidth,
    double safePagePosition,
    int index,
  ) {
    final progress = selectionProgress(safePagePosition, index);
    final width = destinationWidth - horizontalInset * 2;
    if (width <= 0 || progress <= 0) return const SizedBox.shrink();

    final scale = minimumScale + (1 - minimumScale) * progress;
    final start = destinationWidth * index + horizontalInset;
    return PositionedDirectional(
      start: start,
      top: verticalInset,
      bottom: verticalInset,
      width: width,
      child: Transform.scale(
        key: capsuleKeyPrefix == null
            ? null
            : ValueKey<String>('$capsuleKeyPrefix-$index'),
        scale: scale,
        alignment: Alignment.center,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: color.a * progress),
              borderRadius: borderRadius,
            ),
          ),
        ),
      ),
    );
  }
}
