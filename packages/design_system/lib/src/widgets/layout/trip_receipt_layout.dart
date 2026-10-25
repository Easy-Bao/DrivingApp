import 'package:design_system/src/tokens/layout.dart';
import 'package:design_system/src/tokens/palette.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:flutter/material.dart';

/// Quiet receipt chrome shared by passenger and driver ride details.
class TripReceiptLayout extends StatelessWidget {
  const TripReceiptLayout({
    super.key,
    required this.onBack,
    required this.child,
    this.dateLabel,
  });

  final VoidCallback onBack;
  final String? dateLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const toolbarHeight = 72.0;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final neutralColors = colors.brightness == Brightness.light
        ? colors.copyWith(
            surface: AppPalette.white,
            surfaceContainerHighest: colors.onSurface.withValues(alpha: 0.05),
            onSurfaceVariant: colors.onSurface.withValues(alpha: 0.65),
            outlineVariant: colors.onSurface.withValues(alpha: 0.09),
          )
        : colors;
    return Theme(
      data: theme.copyWith(colorScheme: neutralColors),
      child: Scaffold(
        backgroundColor: colors.brightness == Brightness.light
            ? AppPalette.offWhite
            : colors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: toolbarHeight,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          centerTitle: true,
          actions: const [SizedBox(width: kToolbarHeight)],
          title: Text(
            dateLabel ?? 'Ride details',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: neutralColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.contentMaxWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
