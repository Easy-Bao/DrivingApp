import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RideOptionsLoadingView extends StatelessWidget {
  const RideOptionsLoadingView({super.key, this.showPrimaryAction = true});

  final bool showPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.onSurface.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
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
                      color: context.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _buildRouteCard(context),
                const SizedBox(height: 16),
                _buildFareRow(context),
                const SizedBox(height: 16),
                _buildActionButtons(context),
                const SizedBox(height: 16),
                if (showPrimaryAction)
                  const Bone.button(
                    key: ValueKey('ride-options-loading-primary-action'),
                    width: double.infinity,
                    height: 52,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        borderRadius: BorderRadius.circular(18),
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
