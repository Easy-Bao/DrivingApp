import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

class const HomeDestinationSearchHint({
  super.key,
  this.style,
  this.suggestions = const [],
  this.randomize,
  this.random,
  this.changeInterval = const Duration(milliseconds: 3200),
  this.transitionDuration = const Duration(milliseconds: 560),
}) extends StatefulWidget {
  static const searchExamples = <String>[
    'Search Robinsons',
    'Search School',
    'Search Plaza',
    'Search Work',
    'Search Home',
  ];

  final TextStyle? style;
  final List<String> suggestions;
  final bool? randomize;
  final Random? random;
  final Duration changeInterval;
  final Duration transitionDuration;

  @override
  State<HomeDestinationSearchHint> createState() =>
      _HomeDestinationSearchHintState();
}

class _HomeDestinationSearchHintState extends State<HomeDestinationSearchHint>
    with SingleTickerProviderStateMixin {
  static const double _viewportHeight = 26.0;
  static const double _travelDistance = 20.0;
  static const Interval _outgoingFadeInterval = Interval(
    0.0,
    0.52,
    curve: Curves.easeOutCubic,
  );
  static const Interval _incomingSlideInterval = Interval(
    0.08,
    1.0,
    curve: Curves.easeOutQuart,
  );
  static const Interval _incomingFadeInterval = Interval(
    0.16,
    0.88,
    curve: Curves.easeOutCubic,
  );

  late final AnimationController _transitionController;
  late final Random _random;
  Timer? _rotationTimer;
  List<String> _sourcePhrases = const [];
  List<String> _deck = const [];
  var _deckIndex = 0;
  String _currentLabel = HomeDestinationSearchHint.searchExamples.first;
  String _nextLabel = HomeDestinationSearchHint.searchExamples[1];
  var _motionDisabled = false;
  var _hasInitializedDependencies = false;

  bool get _shouldRandomize =>
      widget.randomize ?? widget.suggestions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _random = widget.random ?? Random();
    _transitionController = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    )..addStatusListener(_handleTransitionStatus);
    _initializeDeck(preserveCurrent: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motionDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_hasInitializedDependencies &&
        motionDisabled == _motionDisabled &&
        _rotationTimer != null) {
      return;
    }

    _hasInitializedDependencies = true;
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
  void didUpdateWidget(covariant HomeDestinationSearchHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transitionDuration != widget.transitionDuration) {
      _transitionController.duration = widget.transitionDuration;
    }

    final nextPhrases = _resolvePhrases(widget.suggestions);
    final randomizeChanged =
        (oldWidget.randomize ?? oldWidget.suggestions.isNotEmpty) !=
        _shouldRandomize;
    final phrasesChanged = !listEquals(_sourcePhrases, nextPhrases);

    if (phrasesChanged || randomizeChanged) {
      final previousLabel = _currentLabel;
      _initializeDeck(preserveCurrent: true);
      final switchedToNewPool = !nextPhrases.contains(previousLabel);

      if (_motionDisabled || nextPhrases.length < 2) {
        _stopRotation();
        _transitionController.stop();
        _transitionController.value = 0;
        if (nextPhrases.isNotEmpty) {
          _currentLabel = _deck.first;
          _deckIndex = 0;
          _nextLabel = _peekNextLabel();
        }
      } else if (switchedToNewPool && !_transitionController.isAnimating) {
        _nextLabel = _deck.first;
        _deckIndex = 0;
        _restartRotation();
        unawaited(_transitionController.forward(from: 0));
      } else {
        _startRotation();
      }
    } else if (oldWidget.changeInterval != widget.changeInterval &&
        !_motionDisabled) {
      _restartRotation();
    }
  }

  @override
  void dispose() {
    _stopRotation();
    _transitionController.dispose();
    super.dispose();
  }

  List<String> _resolvePhrases(List<String> rawSuggestions) {
    final seen = <String>{};
    final formatted = <String>[];
    for (final raw in rawSuggestions) {
      final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (trimmed.isEmpty) continue;
      final phrase = trimmed.toLowerCase().startsWith('search ')
          ? trimmed
          : 'Search $trimmed';
      if (seen.add(phrase.toLowerCase())) {
        formatted.add(phrase);
      }
    }
    if (formatted.isEmpty) {
      return HomeDestinationSearchHint.searchExamples;
    }
    return List<String>.unmodifiable(formatted);
  }

  void _initializeDeck({required bool preserveCurrent}) {
    _sourcePhrases = _resolvePhrases(widget.suggestions);
    _deck = _buildDeck(
      _sourcePhrases,
      avoidFirst: preserveCurrent ? _currentLabel : null,
    );
    if (!preserveCurrent) {
      _deckIndex = 0;
      _currentLabel = _deck.first;
      _nextLabel = _peekNextLabel();
    } else {
      final existingIndex = _deck.indexOf(_currentLabel);
      if (existingIndex >= 0) {
        _deckIndex = existingIndex;
        _nextLabel = _peekNextLabel();
      } else {
        _deckIndex = -1;
        _nextLabel = _deck.first;
      }
    }
  }

  List<String> _buildDeck(List<String> phrases, {String? avoidFirst}) {
    final next = List<String>.of(phrases);
    if (_shouldRandomize && next.length > 1) {
      next.shuffle(_random);
      if (avoidFirst != null && next.first == avoidFirst) {
        final swapIndex = 1 + _random.nextInt(next.length - 1);
        final first = next[0];
        next[0] = next[swapIndex];
        next[swapIndex] = first;
      }
    }
    return next;
  }

  String _peekNextLabel() {
    if (_deck.length < 2) return _deck.first;
    final nextIndex = _deckIndex + 1;
    if (nextIndex < _deck.length) {
      return _deck[nextIndex];
    }
    _deck = _buildDeck(_sourcePhrases, avoidFirst: _currentLabel);
    _deckIndex = -1;
    return _deck.first;
  }

  void _startRotation() {
    if (_rotationTimer != null || _sourcePhrases.length < 2) {
      return;
    }
    _rotationTimer = Timer.periodic(widget.changeInterval, (_) {
      if (!mounted || _motionDisabled || _transitionController.isAnimating) {
        return;
      }
      _nextLabel = _peekNextLabel();
      unawaited(_transitionController.forward(from: 0));
    });
  }

  void _restartRotation() {
    _stopRotation();
    _startRotation();
  }

  void _stopRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  void _handleTransitionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    setState(() {
      _currentLabel = _nextLabel;
      final indexInDeck = _deck.indexOf(_currentLabel);
      _deckIndex = indexInDeck >= 0 ? indexInDeck : 0;
      if (_sourcePhrases.length >= 2) {
        _nextLabel = _peekNextLabel();
      }
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
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

                final raw = _transitionController.value;
                final outgoingSlide = Curves.easeInOutCubic.transform(raw);
                final outgoingOpacity =
                    (1.0 - _outgoingFadeInterval.transform(raw)).clamp(
                      0.0,
                      1.0,
                    );
                final outgoingScale =
                    1.0 - 0.04 * Curves.easeOutCubic.transform(raw);

                final incomingProgress = _incomingSlideInterval.transform(raw);
                final incomingSlide = incomingProgress - 1.0;
                final incomingOpacity = _incomingFadeInterval
                    .transform(raw)
                    .clamp(0.0, 1.0);
                final incomingScale = 0.96 + 0.04 * incomingProgress;

                return ShaderMask(
                  key: const ValueKey('search-hint-edge-mask'),
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.16, 0.84, 1.0],
                  ).createShader(bounds),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMovingLabel(
                        label: _currentLabel,
                        offsetY: outgoingSlide * _travelDistance,
                        opacity: outgoingOpacity,
                        scale: outgoingScale,
                        style: textStyle,
                      ),
                      _buildMovingLabel(
                        label: _nextLabel,
                        offsetY: incomingSlide * _travelDistance,
                        opacity: incomingOpacity,
                        scale: incomingScale,
                        style: textStyle,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

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
    required double offsetY,
    required double opacity,
    required double scale,
    required TextStyle style,
  }) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.centerLeft,
        child: Opacity(opacity: opacity, child: _buildLabel(label, style)),
      ),
    );
  }
}
