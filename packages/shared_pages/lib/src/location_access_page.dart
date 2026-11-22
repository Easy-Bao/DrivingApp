import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

enum AppLocationAccessTone { neutral, success, warning, error }

class const AppLocationAccessPresentation({
  required this.icon,
  required this.title,
  required this.message,
  required this.tone,
}) {
  final IconData icon;
  final String title;
  final String message;
  final AppLocationAccessTone tone;
}

class const AppLocationAccessStatusPage({
  super.key,
  required this.presentation,
  required this.onBack,
  this.primaryActionLabel,
  this.onPrimaryAction,
  this.onRetry,
  this.audience = 'pickups and active trip tracking',
}) extends StatelessWidget {
  final AppLocationAccessPresentation presentation;
  final VoidCallback onBack;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onRetry;
  final String audience;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final toneColor = _toneColor(context);

    return AppSecondaryPage(
      title: 'Location access',
      onBack: onBack,
      maxWidth: 600,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 360
              ? AppLayout.pagePadding
              : AppLayout.pagePaddingWide;
          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.xxl,
              horizontalPadding,
              40,
            ),
            children: [
              Column(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: toneColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: toneColor.withValues(alpha: 0.24),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        presentation.icon,
                        size: 26,
                        color: toneColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    presentation.title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      presentation.message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (primaryActionLabel != null && onPrimaryAction != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  height: AppSize.controlHeight,
                  child: FilledButton(
                    key: const ValueKey<String>(
                      'location-access-primary-action',
                    ),
                    onPressed: onPrimaryAction,
                    style:
                        FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.focused)) {
                              return colorScheme.onPrimary.withValues(
                                alpha: 0.16,
                              );
                            }
                            return Colors.transparent;
                          }),
                        ),
                    child: Text(primaryActionLabel!),
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    key: const ValueKey<String>('location-access-retry'),
                    onPressed: onRetry,
                    style:
                        TextButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.focused)) {
                              return colorScheme.primary.withValues(
                                alpha: 0.12,
                              );
                            }
                            return Colors.transparent;
                          }),
                        ),
                    child: const Text('Try again'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxxl),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Semantics(
                header: true,
                child: Text(
                  'WHY EASYRIDE NEEDS LOCATION',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _LocationReason(
                icon: LucideIcons.map_pin,
                title: 'Accurate pickup points',
                message: 'Place pickups where passengers and drivers can meet.',
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                color: colorScheme.outlineVariant.withValues(alpha: 0.65),
              ),
              _LocationReason(
                icon: LucideIcons.navigation,
                title: 'Live trip progress',
                message: 'Keep $audience useful and up to date.',
              ),
            ],
          );
        },
      ),
    );
  }

  Color _toneColor(BuildContext context) {
    return switch (presentation.tone) {
      AppLocationAccessTone.neutral => context.colorScheme.onSurfaceVariant,
      AppLocationAccessTone.success => context.semanticColors.success,
      AppLocationAccessTone.warning => context.semanticColors.warning,
      AppLocationAccessTone.error => context.colorScheme.error,
    };
  }
}

class const _LocationReason({
  required this.icon,
  required this.title,
  required this.message,
}) extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
