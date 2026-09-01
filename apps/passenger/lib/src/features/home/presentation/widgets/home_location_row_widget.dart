import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const HomeLocationRowWidget({
  required this.isAccessChecking,
  required this.hasLocationAccess,
  required this.isAddressLoading,
  required this.currentAddress,
  this.locationErrorMessage = '',
  required this.onRequestLocation,
  required this.onRetryAddress,
  super.key,
}) extends StatelessWidget {
  final bool isAccessChecking;
  final bool hasLocationAccess;
  final bool isAddressLoading;
  final String currentAddress;
  final String locationErrorMessage;
  final VoidCallback onRequestLocation;
  final VoidCallback onRetryAddress;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (isAccessChecking || isAddressLoading) {
      content = const Skeletonizer.zone(
        child: Row(
          children: [
            Bone.icon(size: 14),
            SizedBox(width: 6),
            Bone.text(width: 140, fontSize: 13),
          ],
        ),
      );
    } else if (!hasLocationAccess) {
      content = const _LocationRowLabel(
        label: 'Turn on location to set pickup',
      );
    } else if (currentAddress.isEmpty && locationErrorMessage.isNotEmpty) {
      content = _LocationRowLabel(label: locationErrorMessage, expands: true);
    } else if (currentAddress.isEmpty) {
      content = const _LocationRowLabel(label: 'Finding your pickup location…');
    } else {
      content = _LocationRowLabel(label: currentAddress, expands: true);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tapCallback,
      child: content,
    );
  }

  VoidCallback? get _tapCallback {
    if (isAccessChecking || isAddressLoading) return null;
    if (!hasLocationAccess) return onRequestLocation;
    if (currentAddress.isEmpty) return onRetryAddress;
    return null;
  }
}

class const _LocationRowLabel({required this.label, this.expands = false})
    extends StatelessWidget {
  final String label;
  final bool expands;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.colorScheme.onSurface,
      ),
    );

    return Row(
      children: [
        Icon(
          LucideIcons.map_pin,
          size: 14,
          color: context.colorScheme.onSurface,
        ),
        const SizedBox(width: 6),
        if (expands) Expanded(child: labelWidget) else labelWidget,
      ],
    );
  }
}
