import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AppAuthLayout extends StatelessWidget {
  const AppAuthLayout({
    super.key,
    required this.title,
    required this.description,
    required this.children,
    this.descriptionHighlight,
    this.onBack,
    this.footer,
  });

  final String title;
  final String description;
  final String? descriptionHighlight;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          enabledBorder: border(context.colorScheme.outlineVariant),
          focusedBorder: border(context.colorScheme.primary, width: 1.5),
          errorBorder: border(context.colorScheme.error),
          focusedErrorBorder: border(context.colorScheme.error, width: 1.5),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: theme.filledButtonTheme.style?.copyWith(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: onBack == null
            ? null
            : AppBar(
                leading: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBack,
                  icon: const Icon(LucideIcons.arrow_left),
                ),
              ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter =
                  AppSpacing.xxl +
                  (constraints.maxWidth > 488
                      ? (constraints.maxWidth - 488) / 2
                      : 0);
              return CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.xxl,
                        gutter,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: context.textStyles.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDescription(context),
                          const SizedBox(height: AppSpacing.xxxl),
                          ...children,
                          if (footer != null) ...[
                            const SizedBox(height: AppSpacing.xxl),
                            const Spacer(),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final baseStyle = context.textStyles.bodyMedium?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      height: 1.45,
    );
    final highlight = descriptionHighlight?.trim() ?? '';
    final start = highlight.isEmpty ? -1 : description.indexOf(highlight);
    if (start < 0) {
      return Text(description, style: baseStyle);
    }
    final end = start + highlight.length;
    return Text.rich(
      TextSpan(
        children: [
          if (start > 0) TextSpan(text: description.substring(0, start)),
          TextSpan(
            text: description.substring(start, end),
            style: TextStyle(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (end < description.length)
            TextSpan(text: description.substring(end)),
        ],
      ),
      style: baseStyle,
    );
  }
}
