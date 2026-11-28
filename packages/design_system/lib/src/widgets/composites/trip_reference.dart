import 'dart:async';

import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class TripReference extends StatefulWidget {
  const TripReference({
    super.key,
    required this.id,
    this.label = 'Booking ID',
    this.compact = false,
    this.expanded = false,
  });

  static const Duration copiedResetDuration = Duration(milliseconds: 1800);

  final String id;
  final String label;
  final bool compact;
  final bool expanded;

  @override
  State<TripReference> createState() => _TripReferenceState();
}

class _TripReferenceState extends State<TripReference> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy(String normalizedId) async {
    await Clipboard.setData(ClipboardData(text: normalizedId));
    if (!mounted) return;
    unawaited(HapticFeedback.selectionClick());
    _resetTimer?.cancel();
    setState(() => _copied = true);
    _resetTimer = Timer(TripReference.copiedResetDuration, () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalizedId = widget.id.trim();
    if (normalizedId.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final semanticColors = context.semanticColors;
    final fontSize = widget.compact ? 12.0 : 14.0;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      container: true,
      label: '${widget.label} $normalizedId',
      child: Container(
        padding: EdgeInsets.only(
          left: widget.expanded
              ? 0
              : widget.compact
              ? 10
              : 12,
        ),
        decoration: widget.expanded
            ? null
            : BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
        child: Row(
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (widget.expanded) ...[
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: fontSize,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              fit: widget.expanded ? FlexFit.tight : FlexFit.loose,
              child: SelectableText(
                widget.expanded
                    ? normalizedId
                    : '${widget.label} - $normalizedId',
                textAlign: widget.expanded ? TextAlign.end : TextAlign.start,
                style:
                    (widget.compact
                            ? context.textStyles.bodySmall
                            : context.textStyles.bodyMedium)
                        ?.copyWith(
                          color: colors.onSurface,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
              ),
            ),
            Semantics(
              liveRegion: _copied,
              child: IconButton(
                tooltip: _copied
                    ? '${widget.label} copied'
                    : 'Copy ${widget.label}',
                constraints: const BoxConstraints(
                  minWidth: AppSize.minimumTouchTarget,
                  minHeight: AppSize.minimumTouchTarget,
                ),
                onPressed: () => unawaited(_copy(normalizedId)),
                icon: AnimatedSwitcher(
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: _copied
                      ? Icon(
                          LucideIcons.check,
                          key: const ValueKey<String>('trip-reference-copied'),
                          size: 18,
                          color: semanticColors.success,
                        )
                      : Icon(
                          LucideIcons.copy,
                          key: const ValueKey<String>('trip-reference-copy'),
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
