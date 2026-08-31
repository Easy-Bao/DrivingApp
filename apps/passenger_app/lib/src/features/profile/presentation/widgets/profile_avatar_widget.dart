import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:design_system/design_system.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final String initials;
  final String? imagePath;
  final String? imageData;
  final double size;
  final VoidCallback? onCameraTap;

  const ProfileAvatarWidget({
    super.key,
    required this.initials,
    this.imagePath,
    this.imageData,
    this.size = 72,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = this.imagePath;
    final fallbackImage = _buildImageData(context);
    final avatar = imagePath == null || imagePath.isEmpty
        ? fallbackImage ?? _buildInitials(context)
        : Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallbackImage ?? _buildInitials(context),
          );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(child: SizedBox.expand(child: avatar)),
          if (onCameraTap != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: context.colorScheme.onSurface,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const ValueKey<String>('passenger-profile-camera'),
                  onTap: onCameraTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: size * 0.32,
                    height: size * 0.32,
                    child: Icon(
                      LucideIcons.camera,
                      size: size * 0.16,
                      color: context.colorScheme.surface,
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
      color: context.colorScheme.secondaryContainer,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
