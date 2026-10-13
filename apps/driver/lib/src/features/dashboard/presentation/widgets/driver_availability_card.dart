import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class DriverAvailabilityCard extends StatelessWidget {
  const DriverAvailabilityCard({
    super.key,
    required this.isOnline,
    required this.isToggling,
    required this.hasActiveRide,
    required this.statusPulse,
    required this.onChanged,
  });

  final bool isOnline;
  final bool isToggling;
  final bool hasActiveRide;
  final Animation<double> statusPulse;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EasyRideLayout.pagePadding,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: EasyRideSpacing.lg,
          vertical: hasActiveRide ? EasyRideSpacing.sm : EasyRideSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: hasActiveRide
                  ? Row(
                      children: [
                        _DriverStatusPill(
                          isOnline: isOnline,
                          pulse: statusPulse,
                        ),
                        const SizedBox(width: EasyRideSpacing.sm),
                        Expanded(
                          child: Text(
                            'Active trip',
                            style: context.textStyles.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DriverStatusPill(
                          isOnline: isOnline,
                          pulse: statusPulse,
                        ),
                        const SizedBox(height: EasyRideSpacing.sm),
                        Text(
                          isOnline
                              ? 'Available for ride requests nearby'
                              : 'Switch online to start receiving rides',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: EasyRideSpacing.sm),
            SizedBox(
              width: 64,
              height: EasyRideSize.minimumTouchTarget,
              child: Center(
                child: isToggling
                    ? Semantics(
                        label: 'Updating driver availability',
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isOnline
                                ? context.semanticColors.online
                                : context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : MergeSemantics(
                        child: Semantics(
                          label: 'Driver availability',
                          child: Switch(
                            value: isOnline,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            activeThumbColor: context.semanticColors.onSuccess,
                            activeTrackColor: context.semanticColors.online,
                            inactiveThumbColor:
                                context.colorScheme.onSurfaceVariant,
                            inactiveTrackColor:
                                context.colorScheme.surfaceContainerHighest,
                            onChanged: onChanged,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverStatusPill extends StatelessWidget {
  const _DriverStatusPill({required this.isOnline, required this.pulse});

  final bool isOnline;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline
        ? context.semanticColors.online
        : context.colorScheme.surfaceContainerHighest;
    final foregroundColor = isOnline
        ? context.semanticColors.onSuccess
        : context.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(EasyRideRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, child) => Opacity(
                opacity: isOnline ? 0.55 + pulse.value * 0.45 : 1,
                child: child,
              ),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isOnline
                      ? context.semanticColors.onSuccess
                      : context.semanticColors.offline,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: context.textStyles.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
