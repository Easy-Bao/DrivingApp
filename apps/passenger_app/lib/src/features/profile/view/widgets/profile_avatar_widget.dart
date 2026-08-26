import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final String initials;
  final String? imagePath;
  final double size;
  final VoidCallback? onCameraTap;

  const ProfileAvatarWidget({
    super.key,
    required this.initials,
    this.imagePath,
    this.size = 72,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = this.imagePath;
    final avatar = imagePath == null || imagePath.isEmpty
        ? _buildInitials()
        : Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildInitials(),
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
