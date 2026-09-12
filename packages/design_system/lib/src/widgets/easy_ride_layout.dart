import 'package:design_system/src/theme/easy_ride_design_tokens.dart';
import 'package:design_system/src/theme/design_system_context.dart';
import 'package:design_system/src/widgets/app_floating_tab_bar.dart';
import 'package:flutter/material.dart';

/// A consistent page heading for primary destinations and secondary flows.
///
/// Keeping the heading hierarchy here prevents each feature from inventing a
/// slightly different title size, weight, or subtitle rhythm.
class const EasyRidePageHeader({
  super.key,
  required this.title,
  this.subtitle,
  this.leading,
  this.trailing,
  this.padding = EdgeInsets.zero,
  this.useLargeTitle = true,
}) extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool useLargeTitle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = useLargeTitle
        ? context.textStyles.displayLarge
        : context.textStyles.titleLarge;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: EasyRideDesignTokens.compactGap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: EasyRideDesignTokens.compactGap / 2),
                  Text(
                    subtitle!,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: EasyRideDesignTokens.compactGap),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A centered content frame that keeps wide layouts readable.
class const EasyRidePageFrame({
  super.key,
  required this.child,
  this.padding,
  this.maxWidth = EasyRideDesignTokens.pageMaxWidth,
}) extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            constraints.maxWidth >= EasyRideDesignTokens.wideLayoutBreakpoint
            ? EasyRideDesignTokens.pageHorizontalPaddingWide
            : EasyRideDesignTokens.pageHorizontalPadding;
        final contentPadding =
            padding ??
            EdgeInsets.fromLTRB(
              horizontalPadding,
              EasyRideDesignTokens.pageTopPadding,
              horizontalPadding,
              EasyRideDesignTokens.pageTopPadding,
            );

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: contentPadding, child: child),
          ),
        );
      },
    );
  }
}

/// A restrained surface container for cards and grouped content.
class const EasyRideSurfaceCard({
  super.key,
  required this.child,
  this.padding = const EdgeInsets.all(EasyRideDesignTokens.cardPadding),
  this.color,
  this.radius = EasyRideDesignTokens.cardRadius,
  this.showBorder = true,
}) extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: showBorder
          ? BorderSide(color: colorScheme.outlineVariant)
          : BorderSide.none,
    );

    return Material(
      color: color ?? colorScheme.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Shared wide-screen navigation for both client shells.
class const EasyRideNavigationRail({
  super.key,
  required this.destinations,
  required this.selectedIndex,
  required this.onDestinationSelected,
  this.iconBuilder,
}) extends StatelessWidget {
  final List<AppTabDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppTabIconBuilder? iconBuilder;

  this : assert(destinations.length > 0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final activeIndex = selectedIndex.clamp(0, destinations.length - 1).toInt();

    return NavigationRail(
      selectedIndex: activeIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      useIndicator: true,
      minWidth: 88,
      groupAlignment: -0.8,
      destinations: [
        for (var index = 0; index < destinations.length; index++)
          NavigationRailDestination(
            icon: _icon(
              context,
              index,
              destinations[index],
              colorScheme.onSurfaceVariant,
            ),
            selectedIcon: _icon(
              context,
              index,
              destinations[index],
              colorScheme.onPrimaryContainer,
            ),
            label: Text(destinations[index].label),
          ),
      ],
    );
  }

  Widget _icon(
    BuildContext context,
    int index,
    AppTabDestination destination,
    Color color,
  ) {
    return iconBuilder?.call(context, index, destination, color) ??
        Icon(
          destination.icon,
          size: EasyRideDesignTokens.navigationIconSize,
          color: color,
        );
  }
}
