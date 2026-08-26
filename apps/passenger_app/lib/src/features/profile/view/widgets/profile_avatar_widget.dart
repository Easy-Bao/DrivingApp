import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

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
    final fallbackImage = _buildImageData();
    final avatar = imagePath == null || imagePath.isEmpty
        ? fallbackImage ?? _buildInitials()
        : Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallbackImage ?? _buildInitials(),
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
                color: AppTheme.primaryColor,
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
                      color: AppTheme.surface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildImageData() {
    final value = imageData?.trim() ?? '';
    if (value.isEmpty) return null;
    try {
      final bytes = base64Decode(value);
      if (bytes.isEmpty) return null;
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitials(),
      );
    } on FormatException {
      return null;
    }
  }

  Widget _buildInitials() {
    return ColoredBox(
      color: AppTheme.secondaryColor,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
