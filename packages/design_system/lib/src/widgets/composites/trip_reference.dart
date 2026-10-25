import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';

class const TripReference({
  super.key,
  required this.id,
  this.label = 'Booking ID',
  this.compact = false,
  this.expanded = false,
}) extends StatelessWidget {
  final String id;
  final String label;
  final bool compact;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final fontSize = compact ? 12.0 : 14.0;
    return Semantics(
      container: true,
      label: '$label $normalizedId',
      child: Container(
        padding: EdgeInsets.only(
          left: expanded
              ? 0
              : compact
              ? 10
              : 12,
        ),
        decoration: expanded
            ? null
            : BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (expanded) ...[
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: fontSize,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              fit: expanded ? FlexFit.tight : FlexFit.loose,
              child: SelectableText(
                expanded ? normalizedId : '$label - $normalizedId',
                textAlign: expanded ? TextAlign.end : TextAlign.start,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Copy $label',
              constraints: const BoxConstraints(
                minWidth: AppSize.minimumTouchTarget,
                minHeight: AppSize.minimumTouchTarget,
              ),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: normalizedId));
              },
              icon: Icon(
                Icons.copy_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
