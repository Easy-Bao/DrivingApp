import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/widgets/feedback/toast.dart';

class const TripReference({
  super.key,
  required this.id,
  this.label = 'Booking ID',
  this.compact = false,
}) extends StatelessWidget {
  final String id;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$label $normalizedId',
      child: Container(
        padding: EdgeInsets.only(left: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SelectableText(
                '$label - $normalizedId',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: compact ? 12 : 14,
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
                if (!context.mounted) return;
                CustomToast.show(context, '$label copied');
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
