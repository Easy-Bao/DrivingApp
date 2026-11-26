import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';

Future<void> showSavedPlaceOptionsSheet(
  BuildContext context, {
  required SavedPlace place,
  required VoidCallback onSetDefault,
  required VoidCallback onChangeLocation,
  required VoidCallback onRemove,
}) {
  final colorScheme = context.colorScheme;
  final textStyles = context.textStyles;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    backgroundColor: colorScheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.pagePadding,
            AppSpacing.md,
            AppLayout.pagePadding,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                place.label,
                textAlign: TextAlign.center,
                style: textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (place.savedAddress case final savedAddress?
                  when savedAddress.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  savedAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textStyles.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const SavedPlacesHairline(),
              _SavedPlaceSheetAction(
                icon: place.isDefault
                    ? LucideIcons.circle_check
                    : LucideIcons.circle,
                title: place.isDefault
                    ? 'Default Home quick action'
                    : 'Set as Home quick action',
                subtitle: place.isDefault
                    ? 'Shown as the only saved place on Home'
                    : 'Show this place as the only saved place on Home',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (!place.isDefault) {
                    onSetDefault();
                  }
                },
              ),
              const SavedPlacesHairline(indent: 36),
              _SavedPlaceSheetAction(
                icon: LucideIcons.pencil,
                title: 'Change location',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onChangeLocation();
                },
              ),
              const SavedPlacesHairline(indent: 36),
              _SavedPlaceSheetAction(
                icon: LucideIcons.trash_2,
                title: 'Remove shortcut',
                isDestructive: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onRemove();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SavedPlacesHairline extends StatelessWidget {
  const SavedPlacesHairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.65),
    );
  }
}

class SavedPlacesSectionHeading extends StatelessWidget {
  const SavedPlacesSectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class SavedPlaceTile extends StatelessWidget {
  const SavedPlaceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.address,
    required this.isConfigured,
    required this.isDefault,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String address;
  final bool isConfigured;
  final bool isDefault;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Semantics(
      button: true,
      label: isDefault ? '$label, Default, $address' : '$label, $address',
      child: InkWell(
        key: ValueKey<String>('saved-place-$label'),
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSize.minimumTouchTarget + 18,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isConfigured
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isConfigured
                            ? colorScheme.primary.withValues(alpha: 0.12)
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      color: isConfigured
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      size: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            label,
                            style: textStyles.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (isDefault) const _SavedPlaceDefaultBadge(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ExcludeSemantics(
                  child: Icon(
                    isConfigured ? LucideIcons.chevron_right : LucideIcons.plus,
                    color: colorScheme.onSurfaceVariant,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedPlaceDefaultBadge extends StatelessWidget {
  const _SavedPlaceDefaultBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        'Default',
        style: context.textStyles.labelSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SavedPlaceSheetAction extends StatelessWidget {
  const _SavedPlaceSheetAction({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final foregroundColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      enableFeedback: false,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return foregroundColor.withValues(alpha: 0.12);
        }
        return Colors.transparent;
      }),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSize.minimumTouchTarget + 8,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textStyles.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                    if (subtitle case final subtitleText?) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: textStyles.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
