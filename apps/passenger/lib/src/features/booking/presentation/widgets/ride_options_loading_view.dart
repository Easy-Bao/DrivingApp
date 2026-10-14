import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const RideOptionsLoadingView({super.key, this.showPrimaryAction = true})
    extends StatelessWidget {
  final bool showPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      key: const ValueKey('ride-options-loading'),
      child: Column(
        key: const ValueKey('ride-options-loading-content'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTripSummary(context),
          const SizedBox(height: 16),
          _buildActionRow(context),
          const SizedBox(height: 16),
          _buildTipSelector(),
          const SizedBox(height: 16),
          _buildActionRow(context),
          const SizedBox(height: 12),
          _buildTotalFare(context),
          const SizedBox(height: 12),
          if (showPrimaryAction)
            const Bone.button(
              width: double.infinity,
              height: 50,
              borderRadius: BorderRadius.all(
                Radius.circular(EasyRideRadius.lg),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Bone.icon(size: 18),
              SizedBox(height: 10),
              Bone(width: 2, height: 38),
              SizedBox(height: 10),
              Bone.icon(size: 18),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 48, fontSize: 11),
                SizedBox(height: 3),
                Bone.text(width: 140, fontSize: 14),
                SizedBox(height: 22),
                Bone.text(width: 78, fontSize: 11),
                SizedBox(height: 3),
                Bone.text(width: 120, fontSize: 14),
                SizedBox(height: 3),
                Bone.multiText(lines: 2, width: 210, fontSize: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: const Row(
        children: [
          Bone.square(
            size: 40,
            borderRadius: BorderRadius.all(Radius.circular(EasyRideRadius.md)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 100, fontSize: 14),
                SizedBox(height: 4),
                Bone.text(width: 190, fontSize: 12),
              ],
            ),
          ),
          SizedBox(width: 8),
          Bone.icon(size: 19),
        ],
      ),
    );
  }

  Widget _buildTipSelector() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Bone.text(width: 72, fontSize: 14),
        SizedBox(height: 4),
        Bone.text(width: 190, fontSize: 12),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Bone.button(
                width: 56,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 50,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 50,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 50,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 50,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 56,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalFare(BuildContext context) {
    return Container(
      key: const ValueKey('ride-options-loading-total-fare'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 82, fontSize: 15),
                SizedBox(height: 4),
                Bone.text(width: 130, fontSize: 12),
              ],
            ),
          ),
          Bone.text(width: 56, fontSize: 20),
          SizedBox(width: 8),
          Bone.icon(size: 18),
        ],
      ),
    );
  }
}
