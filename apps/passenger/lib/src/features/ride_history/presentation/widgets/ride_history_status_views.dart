import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_header.dart';
import 'package:skeletonizer/skeletonizer.dart';

double _rideHistoryBottomClearance(BuildContext context) {
  return AppFloatingTabBar.height + MediaQuery.paddingOf(context).bottom + 10;
}

class RideHistoryMessageView extends StatelessWidget {
  const RideHistoryMessageView({
    super.key,
    required this.subtitle,
    required this.title,
    required this.message,
    this.headerTitle = 'Activity',
    this.showBackButton = false,
    this.showSubtitle = true,
    this.icon = LucideIcons.route,
    this.actionLabel,
    this.onAction,
  });

  final String subtitle;
  final String title;
  final String message;
  final String headerTitle;
  final bool showBackButton;
  final bool showSubtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? AppLayout.pagePadding
        : AppLayout.pagePaddingWide;
    final label = actionLabel;
    final action = onAction;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.sm,
            horizontalPadding,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeader(
              title: headerTitle,
              subtitle: showSubtitle ? subtitle : null,
              showBackButton: showBackButton,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              32,
              24,
              32,
              _rideHistoryBottomClearance(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon case final iconData?) ...[
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      iconData,
                      size: 24,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
                if (label != null && action != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextButton.icon(
                    onPressed: action,
                    style:
                        TextButton.styleFrom(
                          foregroundColor: colors.onSurface,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size(
                            0,
                            AppSize.minimumTouchTarget,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? colors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                        ),
                    icon: const Icon(LucideIcons.refresh_cw, size: 16),
                    label: Text(label),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RideHistoryLoadingView extends StatelessWidget {
  const RideHistoryLoadingView({
    super.key,
    required this.itemCount,
    this.title = 'Activity',
    this.subtitle = 'Your trips and receipts',
    this.showBackButton = false,
    this.showSubtitle = true,
    this.showSummary = true,
    this.showFilters = true,
  });

  final int itemCount;
  final String title;
  final String subtitle;
  final bool showBackButton;
  final bool showSubtitle;
  final bool showSummary;
  final bool showFilters;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? AppLayout.pagePadding
        : AppLayout.pagePaddingWide;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.sm,
            horizontalPadding,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeader(
              title: title,
              subtitle: showSubtitle ? subtitle : null,
              showBackButton: showBackButton,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: Skeletonizer.sliver(
            key: const ValueKey<String>('activity-loading-skeleton'),
            child: SliverList(
              delegate: SliverChildListDelegate([
                if (showSummary) ...[
                  const KeyedSubtree(
                    key: ValueKey<String>('activity-loading-summary'),
                    child: _ActivitySkeletonSummary(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (showFilters) ...[
                  const KeyedSubtree(
                    key: ValueKey<String>('activity-loading-filters'),
                    child: _ActivitySkeletonFilters(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                for (var index = 0; index < itemCount; index++) ...[
                  if (index == 0) ...[
                    const Bone.text(width: 92, fontSize: 12),
                    const SizedBox(height: AppSpacing.xs),
                  ] else
                    Divider(
                      height: 1,
                      indent: 54,
                      color: context.colorScheme.outlineVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  const _ActivitySkeletonRideRow(),
                ],
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: _rideHistoryBottomClearance(context)),
        ),
      ],
    );
  }
}

class _ActivitySkeletonSummary extends StatelessWidget {
  const _ActivitySkeletonSummary();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            const Expanded(child: _ActivitySkeletonMetric(valueWidth: 68)),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
              color: colors.outlineVariant.withValues(alpha: 0.7),
            ),
            const Expanded(child: _ActivitySkeletonMetric(valueWidth: 30)),
          ],
        ),
      ),
    );
  }
}

class _ActivitySkeletonMetric extends StatelessWidget {
  const _ActivitySkeletonMetric({required this.valueWidth});

  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Bone.text(width: 68, fontSize: 12),
          const SizedBox(height: AppSpacing.xs),
          Bone.text(width: valueWidth, fontSize: 22),
        ],
      ),
    );
  }
}

class _ActivitySkeletonFilters extends StatelessWidget {
  const _ActivitySkeletonFilters();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: const SizedBox(
        height: AppSize.minimumTouchTarget,
        child: Row(
          children: [
            Expanded(child: Center(child: Bone.text(width: 32, fontSize: 14))),
            Expanded(child: Center(child: Bone.text(width: 72, fontSize: 14))),
            Expanded(child: Center(child: Bone.text(width: 68, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

class _ActivitySkeletonRideRow extends StatelessWidget {
  const _ActivitySkeletonRideRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Bone.circle(size: 40),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 146, fontSize: 15),
                SizedBox(height: 4),
                Bone.text(width: 104, fontSize: 13),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Bone.text(width: 48, fontSize: 14),
          SizedBox(width: AppSpacing.xs),
          Bone.icon(size: 16),
        ],
      ),
    );
  }
}
