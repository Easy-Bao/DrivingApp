import 'package:cached_network_image/cached_network_image.dart';
import 'package:design_system/src/tokens/palette.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const AppNetworkImage({
  super.key,
  required this.imageUrl,
  this.width = 56,
  this.height = 56,
  this.fit = BoxFit.cover,
  this.borderRadius,
  this.fallbackIcon = LucideIcons.user,
}) extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  static bool _isValidHttpUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final url = imageUrl?.trim() ?? '';

    if (!_isValidHttpUrl(url)) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: effectiveRadius,
          border: Border.all(color: AppPalette.imageOutline, width: 1),
        ),
        child: Icon(
          fallbackIcon,
          color: colors.onSurfaceVariant,
          size: width * 0.45,
        ),
      );
    }

    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final memCacheWidth = width.isFinite && width > 0
        ? (width * dpr).round()
        : null;
    final memCacheHeight = height.isFinite && height > 0
        ? (height * dpr).round()
        : null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        border: Border.all(color: AppPalette.imageOutline, width: 1),
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          fit: fit,
          placeholder: (context, _) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: effectiveRadius,
            ),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          errorWidget: (context, _, error) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: effectiveRadius,
            ),
            child: Icon(
              fallbackIcon,
              color: colors.onSurfaceVariant,
              size: width * 0.45,
            ),
          ),
        ),
      ),
    );
  }
}

typedef AppNetworkImageWidget = AppNetworkImage;
