import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/palette.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Standard hairline bottom sheet surface with optional drag handle and safe
/// bottom inset handling.
class const AppBottomSheetContainer({
  super.key,
  required this.child,
  this.showDragHandle = true,
  this.padding = const EdgeInsets.fromLTRB(
    AppSpacing.xl,
    AppSpacing.sm + 2,
    AppSpacing.xl,
    AppSpacing.xl,
  ),
  this.maxWidth = 600,
  this.backgroundColor,
  this.showShadow = false,
}) extends StatelessWidget {
  final Widget child;
  final bool showDragHandle;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final Color? backgroundColor;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor ?? colors.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            border: Border(top: BorderSide(color: colors.outlineVariant)),
            boxShadow: showShadow
                ? const [
                    BoxShadow(
                      color: AppPalette.keyShadow,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                    BoxShadow(
                      color: AppPalette.ambientShadow,
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDragHandle) ...[
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.outlineVariant,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      child,
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
