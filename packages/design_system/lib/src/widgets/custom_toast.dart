import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:design_system/src/theme/easy_ride_theme_context.dart';

class CustomToast {
  CustomToast._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    dismiss();
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message, isError: isError),
    );

    overlayState.insert(overlayEntry);
    _activeEntry = overlayEntry;

    _dismissTimer = Timer(duration, () {
      if (identical(_activeEntry, overlayEntry)) {
        dismiss();
      }
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    final entry = _activeEntry;
    _activeEntry = null;
    try {
      entry?.remove();
    } catch (_) {}
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;

  const _ToastWidget({required this.message, required this.isError});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  Timer? _reverseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _offset = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    unawaited(_controller.forward());

    _reverseTimer = Timer(const Duration(milliseconds: 2700), () {
      if (mounted) {
        unawaited(_controller.reverse());
      }
    });
  }

  @override
  void dispose() {
    _reverseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final successColor = context.semanticColors.success;
    final foregroundColor = widget.isError
        ? colorScheme.onErrorContainer
        : successColor;
    final backgroundColor = widget.isError
        ? colorScheme.errorContainer
        : successColor.withValues(alpha: 0.12);
    final borderColor = widget.isError
        ? colorScheme.error.withValues(alpha: 0.42)
        : successColor.withValues(alpha: 0.42);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
          child: SlideTransition(
            position: _offset,
            child: FadeTransition(
              opacity: _opacity,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isError
                            ? LucideIcons.circle_alert
                            : LucideIcons.circle_check_big,
                        color: foregroundColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: foregroundColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
