import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/src/themes/app_themes.dart';

class AppNetworkImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  const AppNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width = 56,
    this.height = 56,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = LucideIcons.user,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);
    final url = imageUrl?.trim() ?? '';

    if (url.isEmpty || !url.startsWith('http')) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: effectiveRadius,
        ),
        child: Icon(fallbackIcon, color: AppTheme.primaryColor, size: width * 0.45),
      );
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, _) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.neutralColor,
            borderRadius: effectiveRadius,
          ),
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        errorWidget: (context, _, __) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: effectiveRadius,
          ),
          child: Icon(fallbackIcon, color: AppTheme.primaryColor, size: width * 0.45),
        ),
      ),
    );
  }
}
