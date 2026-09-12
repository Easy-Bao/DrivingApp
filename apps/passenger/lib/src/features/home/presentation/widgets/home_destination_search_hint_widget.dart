import 'dart:async';

import 'package:flutter/material.dart';

class const HomeDestinationSearchHintWidget({
  super.key,
  this.style,
  this.changeInterval = const Duration(seconds: 3),
  this.transitionDuration = const Duration(milliseconds: 420),
}) extends StatefulWidget {
  static const searchExamples = <String>[
    'Search Robinsons',
    'Search School',
    'Search Plaza',
    'Search Work',
    'Search Home',
  ];

  final TextStyle? style;
  final Duration changeInterval;
  final Duration transitionDuration;

  @override
  State<HomeDestinationSearchHintWidget> createState() =>
      _HomeDestinationSearchHintWidgetState();
}

class _HomeDestinationSearchHintWidgetState
    extends State<HomeDestinationSearchHintWidget>
    with SingleTickerProviderStateMixin {
  static const _viewportHeight = 22.0;

  late final AnimationController _transitionController;
  Timer? _rotationTimer;
  var _currentIndex = 0;
  var _motionDisabled = false;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    )..addStatusListener(_handleTransitionStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motionDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (motionDisabled == _motionDisabled && _rotationTimer != null) return;

    _motionDisabled = motionDisabled;
    if (_motionDisabled) {
      _stopRotation();
      _transitionController.stop();
      _transitionController.value = 0;
    } else {
      _startRotation();
    }
  }

  @override
  void dispose() {
    _stopRotation();
    _transitionController.dispose();
    super.dispose();
  }

  void _startRotation() {
    if (_rotationTimer != null ||
        HomeDestinationSearchHintWidget.searchExamples.length < 2) {
      return;
    }
    _rotationTimer = Timer.periodic(widget.changeInterval, (_) {
      if (!mounted || _motionDisabled || _transitionController.isAnimating) {
        return;
      }
      unawaited(_transitionController.forward(from: 0));
    });
  }

  void _stopRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  void _handleTransitionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    setState(() {
      _currentIndex =
          (_currentIndex + 1) %
          HomeDestinationSearchHintWidget.searchExamples.length;
    });
    _transitionController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        widget.style ??
        TextStyle(
          fontSize: 16,
          height: 1.25,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        );

    return Semantics(
      label: 'Search for a destination',
      child: ExcludeSemantics(
        child: SizedBox(
          height: _viewportHeight,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _transitionController,
              builder: (context, _) {
                if (!_transitionController.isAnimating || _motionDisabled) {
                  return _buildLabel(_currentLabel, textStyle);
                }

                final progress = Curves.easeOutCubic.transform(
                  _transitionController.value,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildMovingLabel(
                      label: _currentLabel,
                      offset: progress,
                      opacity: 1 - progress,
                      style: textStyle,
                    ),
                    _buildMovingLabel(
                      label: _nextLabel,
                      offset: progress - 1,
                      opacity: progress,
                      style: textStyle,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String get _currentLabel =>
      HomeDestinationSearchHintWidget.searchExamples[_currentIndex];

  String get _nextLabel =>
      HomeDestinationSearchHintWidget.searchExamples[(_currentIndex + 1) %
          HomeDestinationSearchHintWidget.searchExamples.length];

  Widget _buildLabel(String label, TextStyle style) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  Widget _buildMovingLabel({
    required String label,
    required double offset,
    required double opacity,
    required TextStyle style,
  }) {
    return Transform.translate(
      offset: Offset(0, offset * _viewportHeight),
      child: Opacity(opacity: opacity, child: _buildLabel(label, style)),
    );
  }
}
