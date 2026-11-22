import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/layout.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/size.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:design_system/src/widgets/layout/responsive_layout.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const AppSettingsScaffold({
  super.key,
  required this.onBack,
  required this.children,
  this.title = 'Settings',
  this.heading = 'App preferences',
  this.description = 'Manage access and support for this app.',
}) extends StatelessWidget {
  final VoidCallback onBack;
  final List<Widget> children;
  final String title;
  final String heading;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppSecondaryPage(
      title: title,
      onBack: onBack,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 360
              ? AppLayout.pagePadding
              : AppLayout.pagePaddingWide;
          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.md,
              horizontalPadding,
              40,
            ),
            children: [
              Text(
                heading,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Divider(
                height: 1,
                thickness: 1,
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ...children,
            ],
          );
        },
      ),
    );
  }
}

class const AppSettingsSection({
  super.key,
  required this.label,
  required this.children,
}) extends StatelessWidget {
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.65,
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class const AppSettingsNavigationTile({
  super.key,
  required this.icon,
  required this.title,
  required this.subtitle,
  required this.onTap,
}) extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        key: ValueKey<String>('settings-destination-$title'),
        onTap: onTap,
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
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
    );
  }
}
