import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RideOptionsLoadingView extends StatelessWidget {
  const RideOptionsLoadingView({super.key, this.showPrimaryAction = true});

  final bool showPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        border: Border(top: BorderSide(color: colors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Skeletonizer.zone(
            key: const ValueKey('ride-options-loading'),
            child: Column(
              key: const ValueKey('ride-options-loading-content'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _buildRouteCard(context),
                const SizedBox(height: AppSpacing.lg),
                _buildFareRow(context),
                const SizedBox(height: AppSpacing.lg),
                _buildActionButtons(context),
                const SizedBox(height: AppSpacing.lg),
                if (showPrimaryAction)
                  const Bone.button(
                    key: ValueKey('ride-options-loading-primary-action'),
                    width: double.infinity,
                    height: AppSize.controlHeight,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.lg),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: const Row(
        children: [
          Column(
            children: [
              Bone.circle(size: 14),
              SizedBox(height: 4),
              Bone(width: 2, height: 22),
              SizedBox(height: 4),
              Bone.square(
                size: 12,
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ],
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 48, fontSize: 11),
                SizedBox(height: 4),
                Bone.text(width: 140, fontSize: 15),
                SizedBox(height: 10),
                Bone.text(width: 68, fontSize: 11),
                SizedBox(height: 4),
                Bone.text(width: 160, fontSize: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(BuildContext context) {
    return Container(
      key: const ValueKey('ride-options-loading-total-fare'),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone.text(width: 90, fontSize: 13),
              SizedBox(height: 4),
              Bone.text(width: 120, fontSize: 32),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Bone.text(width: 75, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Bone.button(
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Bone.button(
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Bone.button(
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ],
    );
  }
}
