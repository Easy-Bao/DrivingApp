import 'package:flutter/material.dart';
import 'package:shared_ui/src/theme/easy_ride_theme.dart';

/// A selectable appearance option with a compact preview of the app palette.
class ThemeModeCard extends StatelessWidget {
  final ThemeMode mode;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeModeCard({
    super.key,
    required this.mode,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title appearance',
      child: Material(
        color: isSelected
            ? colors.primaryContainer
            : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('theme-mode-card-${mode.name}'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 118),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _ThemePreview(mode: mode),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    key: ValueKey<String>(
                      'theme-mode-card-${mode.name}-${isSelected ? 'selected' : 'unselected'}',
                    ),
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.outline,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 17, color: colors.onPrimary)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final ThemeMode mode;

  const _ThemePreview({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: switch (mode) {
        ThemeMode.system => const Row(
          children: [
            Expanded(child: _MiniAppPreview(brightness: Brightness.light)),
            Expanded(child: _MiniAppPreview(brightness: Brightness.dark)),
          ],
        ),
        ThemeMode.light => const _MiniAppPreview(brightness: Brightness.light),
        ThemeMode.dark => const _MiniAppPreview(brightness: Brightness.dark),
      },
    );
  }
}

class _MiniAppPreview extends StatelessWidget {
  final Brightness brightness;

  const _MiniAppPreview({required this.brightness});

  @override
  Widget build(BuildContext context) {
    final theme = brightness == Brightness.dark
        ? EasyRideTheme.dark
        : EasyRideTheme.light;
    final colors = theme.colorScheme;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 5,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: colors.outlineVariant),
                ),
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 4, color: colors.onSurface),
                    const SizedBox(height: 4),
                    FractionallySizedBox(
                      widthFactor: 0.65,
                      child: Container(
                        height: 3,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
