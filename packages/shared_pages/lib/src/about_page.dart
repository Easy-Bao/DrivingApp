import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const AppAboutPage({
  super.key,
  required this.applicationName,
  required this.applicationVersion,
  required this.description,
  required this.icon,
  required this.onBack,
  required this.onLicensesTap,
}) extends StatelessWidget {
  final String applicationName;
  final String applicationVersion;
  final String description;
  final IconData icon;
  final VoidCallback onBack;
  final VoidCallback onLicensesTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppSecondaryPage(
      title: 'About EasyRide',
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
              AppSpacing.xxxl,
              horizontalPadding,
              48,
            ),
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 28, color: colorScheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                applicationName,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Version $applicationVersion',
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.tabular.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
              Semantics(
                button: true,
                label: 'Open-source licenses. Libraries used to build EasyRide',
                child: InkWell(
                  key: const ValueKey<String>('about-open-source-licenses'),
                  onTap: onLicensesTap,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return colorScheme.primary.withValues(alpha: 0.12);
                    }
                    return Colors.transparent;
                  }),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSize.minimumTouchTarget + 18,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                LucideIcons.code_xml,
                                size: 17,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Open-source licenses',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Libraries used to build EasyRide',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ExcludeSemantics(
                            child: Icon(
                              LucideIcons.chevron_right,
                              size: 17,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ],
          );
        },
      ),
    );
  }
}
