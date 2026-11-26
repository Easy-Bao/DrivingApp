import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/driver_document.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const DocumentPhotoPreview({
  super.key,
  required this.bytes,
  required this.isUploading,
  required this.onChoosePhoto,
}) extends StatelessWidget {
  final Uint8List? bytes;
  final bool isUploading;
  final VoidCallback onChoosePhoto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final imageBytes = bytes;

    if (imageBytes == null) {
      return Semantics(
        button: true,
        label: 'No photo selected. Take a photo',
        child: InkWell(
          onTap: isUploading ? null : onChoosePhoto,
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
          child: Container(
            key: const ValueKey('driver-document-empty-preview'),
            constraints: const BoxConstraints(minHeight: 184),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.camera,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No photo selected',
                  style: textStyles.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Use good lighting so all edges and text stay legible.',
                  textAlign: TextAlign.center,
                  style: textStyles.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cacheWidth = (560 * MediaQuery.devicePixelRatioOf(context)).round();
    return Container(
      key: const ValueKey('driver-document-photo-preview'),
      height: 184,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(
        imageBytes,
        height: 184,
        width: double.infinity,
        cacheWidth: cacheWidth > 0 ? cacheWidth : null,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            'Preview unavailable',
            style: textStyles.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class const DocumentTypeSelector({
  super.key,
  required this.selected,
  required this.enabled,
  required this.onSelected,
}) extends StatelessWidget {
  final DriverDocumentType selected;
  final bool enabled;
  final ValueChanged<DriverDocumentType> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 290 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final options = [
            _DocumentTypeOption(
              key: const ValueKey<String>('driver-document-type-license'),
              icon: LucideIcons.id_card,
              label: "Driver's license",
              isSelected: selected == DriverDocumentType.driverLicense,
              duration: animationDuration,
              onTap: enabled
                  ? () => onSelected(DriverDocumentType.driverLicense)
                  : null,
            ),
            _DocumentTypeOption(
              key: const ValueKey<String>('driver-document-type-registration'),
              icon: LucideIcons.file_text,
              label: 'Vehicle registration',
              isSelected: selected == DriverDocumentType.vehicleRegistration,
              duration: animationDuration,
              onTap: enabled
                  ? () => onSelected(DriverDocumentType.vehicleRegistration)
                  : null,
            ),
          ];
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                options[0],
                const SizedBox(height: AppSpacing.xs),
                options[1],
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: options[0]),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: options[1]),
            ],
          );
        },
      ),
    );
  }
}

class const _DocumentTypeOption({
  super.key,
  required this.icon,
  required this.label,
  required this.isSelected,
  required this.duration,
  required this.onTap,
}) extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Duration duration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final foreground = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(
            minHeight: AppSize.minimumTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 16, color: foreground)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
