import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

class SettingsThemeSelectorWidget extends StatelessWidget {
  final String selectedThemeMode;
  final ValueChanged<String> onThemeSelected;

  const SettingsThemeSelectorWidget({
    super.key,
    required this.selectedThemeMode,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose Theme',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select how EasyRide appears on your device',
            style: TextStyle(
              fontSize: 13,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _buildThemeTile(
            context,
            modeKey: 'system',
            title: 'System Default',
            subtitle: 'Follow your device system setting',
            icon: LucideIcons.smartphone,
          ),
          _buildThemeTile(
            context,
            modeKey: 'light',
            title: 'Light Mode',
            subtitle: 'Clean bright visual theme',
            icon: LucideIcons.sun,
          ),
          _buildThemeTile(
            context,
            modeKey: 'dark',
            title: 'Dark Mode',
            subtitle: 'Sleek dark interface with reduced glare',
            icon: LucideIcons.moon,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required String modeKey,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedThemeMode == modeKey;
    return GestureDetector(
      onTap: () {
        onThemeSelected(modeKey);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorScheme.primary
              : context.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? context.colorScheme.onSurface
                : context.colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? context.colorScheme.onPrimary
                          : context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? context.colorScheme.onPrimary.withValues(
                              alpha: 0.72,
                            )
                          : context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.check,
                  size: 14,
                  color: context.colorScheme.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
