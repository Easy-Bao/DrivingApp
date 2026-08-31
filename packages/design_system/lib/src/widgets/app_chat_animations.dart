import 'dart:async';

import 'package:flutter/material.dart';

class AppChatMessageTransition extends StatefulWidget {
  static const defaultDuration = Duration(milliseconds: 240);

  final Widget child;
  final bool animate;
  final bool isOutgoing;
  final Duration duration;

  const AppChatMessageTransition({
    super.key,
    required this.child,
    required this.animate,
    required this.isOutgoing,
    this.duration = defaultDuration,
  });

  @override
  State<AppChatMessageTransition> createState() =>
      _AppChatMessageTransitionState();
}

class _AppChatMessageTransitionState extends State<AppChatMessageTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  late final Animation<Offset> _position;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final horizontalOffset = widget.isOutgoing ? 0.1 : -0.1;
    _position = Tween<Offset>(
      begin: Offset(horizontalOffset, 0.12),
      end: Offset.zero,
    ).animate(_curve);
    _scale = Tween<double>(begin: 0.94, end: 1).animate(_curve);
    if (widget.animate) {
      unawaited(_controller.forward());
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant AppChatMessageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      unawaited(_controller.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: _position,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

class AppChatTypingIndicator extends StatefulWidget {
  static const _defaultBubbleRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(20),
  );

  final Color bubbleColor;
  final Color dotColor;
  final String semanticLabel;
  final BorderRadius borderRadius;

  const AppChatTypingIndicator({
    super.key,
    required this.bubbleColor,
    required this.dotColor,
    required this.semanticLabel,
    this.borderRadius = _defaultBubbleRadius,
  });

  @override
  State<AppChatTypingIndicator> createState() => _AppChatTypingIndicatorState();
}

class _AppChatTypingIndicatorState extends State<AppChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: RepaintBoundary(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.bubbleColor,
              borderRadius: widget.borderRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < 3; index++) _buildDot(index),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = (_controller.value + index * 0.18) % 1;
        final triangle = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
        final pulse = Curves.easeInOut.transform(triangle);
        final color = Color.lerp(
          widget.dotColor.withValues(alpha: 0.45),
          widget.dotColor,
          pulse,
        )!;

        return Transform.translate(
          key: ValueKey<String>('app-chat-typing-dot-$index'),
          offset: Offset(0, -3 * pulse),
          child: Transform.scale(
            scale: 0.78 + 0.3 * pulse,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox(
                width: 6,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animates the small delivery acknowledgement without changing the bubble's
/// layout. The message entrance and this status transition can therefore run
/// together when the server echoes an accepted message.
class AppChatDeliveryIndicator extends StatelessWidget {
  final bool isSending;
  final bool isDelivered;
  final bool isFailed;
  final Color color;
  final double size;

  const AppChatDeliveryIndicator({
    super.key,
    required this.isSending,
    required this.isDelivered,
    required this.isFailed,
    required this.color,
    this.size = 13,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch ((isSending, isDelivered, isFailed)) {
      (true, _, _) => (Icons.schedule, 'Sending'),
      (_, _, true) => (Icons.refresh, 'Not delivered'),
      (_, true, _) => (Icons.done_all, 'Delivered'),
      _ => (Icons.done, 'Sent'),
    };

    return Semantics(
      label: label,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Icon(
          icon,
          key: ValueKey<IconData>(icon),
          size: size,
          color: color,
        ),
      ),
    );
  }
}
