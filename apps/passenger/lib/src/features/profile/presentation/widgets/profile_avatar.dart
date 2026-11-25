import 'dart:convert';
import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.imagePath,
    this.imageData,
    this.size = 72,
    this.onCameraTap,
  });

  final String initials;
  final String? imagePath;
  final String? imageData;
  final double size;
  final VoidCallback? onCameraTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cameraButtonSize = size * 0.34 < AppSize.minimumTouchTarget
        ? AppSize.minimumTouchTarget
        : size * 0.34;
    final cameraIconSize = size * 0.16 < 16 ? 16.0 : size * 0.16;
    final imagePath = this.imagePath;
    final fallbackImage = _buildImageData(context);
    final avatar = imagePath == null || imagePath.isEmpty
        ? fallbackImage ?? _buildInitials(context)
        : Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallbackImage ?? _buildInitials(context),
          );

    final avatarCircle = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipOval(child: SizedBox.expand(child: avatar)),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (onCameraTap != null)
            Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onCameraTap,
                customBorder: const CircleBorder(),
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
                child: avatarCircle,
              ),
            )
          else
            avatarCircle,
          if (onCameraTap != null)
            Positioned(
              right: -4,
              bottom: -4,
              child: Semantics(
                button: true,
                label: 'Change profile photo',
                child: InkWell(
                  key: const ValueKey<String>('passenger-profile-camera'),
                  onTap: onCameraTap,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return colorScheme.primary.withValues(alpha: 0.16);
                    }
                    return Colors.transparent;
                  }),
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: cameraButtonSize,
                    height: cameraButtonSize,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.canvasColor,
                            width: 2.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.camera,
                          size: cameraIconSize,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildImageData(BuildContext context) {
    final value = imageData?.trim() ?? '';
    if (value.isEmpty) return null;
    try {
      final bytes = base64Decode(value);
      if (bytes.isEmpty) return null;
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitials(context),
      );
    } on FormatException {
      return null;
    }
  }

  Widget _buildInitials(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initials,
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colorScheme.onPrimaryContainer,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
