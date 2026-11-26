import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class ProfileAvatar extends StatefulWidget {
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

  static final Map<String, Uint8List> _decodedCache = <String, Uint8List>{};
  static const int _maxCacheEntries = 4;

  static Uint8List? _decodeCached(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final cached = _decodedCache.remove(value);
    if (cached != null) {
      _decodedCache[value] = cached;
      return cached;
    }
    try {
      final bytes = base64Decode(value);
      if (bytes.isEmpty) return null;
      if (_decodedCache.length >= _maxCacheEntries) {
        _decodedCache.remove(_decodedCache.keys.first);
      }
      _decodedCache[value] = bytes;
      return bytes;
    } on FormatException {
      return null;
    }
  }

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Uint8List? _decodedBytes;

  @override
  void initState() {
    super.initState();
    _decodedBytes = ProfileAvatar._decodeCached(widget.imageData);
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageData != oldWidget.imageData) {
      _decodedBytes = ProfileAvatar._decodeCached(widget.imageData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cameraButtonSize = widget.size * 0.34 < AppSize.minimumTouchTarget
        ? AppSize.minimumTouchTarget
        : widget.size * 0.34;
    final cameraIconSize = widget.size * 0.16 < 16 ? 16.0 : widget.size * 0.16;
    final cacheWidth = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, 1024);
    final imagePath = widget.imagePath;

    final avatar = imagePath == null || imagePath.isEmpty
        ? _buildFallbackImage(context, cacheWidth: cacheWidth)
        : Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            errorBuilder: (_, _, _) =>
                _buildFallbackImage(context, cacheWidth: cacheWidth),
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

    final onCameraTap = widget.onCameraTap;
    return SizedBox(
      width: widget.size,
      height: widget.size,
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

  Widget _buildFallbackImage(BuildContext context, {required int cacheWidth}) {
    final bytes = _decodedBytes;
    if (bytes == null || bytes.isEmpty) {
      return _buildInitials(context);
    }
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => _buildInitials(context),
    );
  }

  Widget _buildInitials(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          widget.initials,
          style: context.textStyles.titleLarge?.copyWith(
            color: context.colorScheme.onPrimaryContainer,
            fontSize: widget.size * 0.28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
