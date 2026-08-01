import 'package:flutter/material.dart';
import 'package:shared_ui/src/themes/app_theme.dart';

class SkeletonListWidget extends StatelessWidget {
  final int? itemCount;
  final EdgeInsetsGeometry padding;
  final bool hasLeadingAvatar;
  final bool hasTrailingIcon;
  final double itemHeight;

  const SkeletonListWidget({
    super.key,
    this.itemCount,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.hasLeadingAvatar = true,
    this.hasTrailingIcon = true,
    this.itemHeight = 44,
  });

  @override
  Widget build(BuildContext context) {
    const titleWidths = [160.0, 200.0, 140.0, 180.0, 150.0, 190.0];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        final int effectiveCount = itemCount ??
            (availableHeight > 0
                ? (availableHeight / (itemHeight + 20)).ceil().clamp(6, 20)
                : 8);

        return ListView.separated(
          padding: padding,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: effectiveCount,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppTheme.borderSide),
          itemBuilder: (_, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  if (hasLeadingAvatar) ...[
                    Container(
                      width: itemHeight,
                      height: itemHeight,
                      decoration: const BoxDecoration(
                        color: AppTheme.neutralColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: titleWidths[index % titleWidths.length],
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.neutralColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.neutralColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasTrailingIcon) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppTheme.neutralColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
