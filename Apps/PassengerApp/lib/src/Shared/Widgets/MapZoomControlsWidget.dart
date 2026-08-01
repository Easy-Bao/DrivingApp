import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/src/Themes/AppTheme.dart';

class MapZoomControlsWidget extends StatelessWidget {
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;

  const MapZoomControlsWidget({
    super.key,
    this.onZoomIn,
    this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderSide.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: LucideIcons.plus,
            onTap: onZoomIn,
            isTop: true,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.borderSide.withValues(alpha: 0.5),
          ),
          _ZoomButton(
            icon: LucideIcons.minus,
            onTap: onZoomOut,
            isTop: false,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isTop;

  const _ZoomButton({
    required this.icon,
    required this.isTop,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTop ? 16 : 0),
          topRight: Radius.circular(isTop ? 16 : 0),
          bottomLeft: Radius.circular(isTop ? 0 : 16),
          bottomRight: Radius.circular(isTop ? 0 : 16),
        ),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
