import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/src/theme/easy_ride_theme_context.dart';
import 'package:shared_ui/src/theme/theme_mode_cubit.dart';
import 'package:shared_ui/src/widgets/theme_mode_card.dart';

/// The shared system, light, and dark appearance selector.
class AppAppearancePage extends StatelessWidget {
  const AppAppearancePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
          icon: const Icon(LucideIcons.arrow_left),
        ),
        title: const Text('Appearance'),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: BlocBuilder<ThemeModeCubit, ThemeMode>(
            builder: (context, selectedMode) => ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              children: [
                Text(
                  'Choose how BaoRide looks',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your choice applies immediately across the entire app.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ThemeModeCard(
                  mode: ThemeMode.system,
                  title: 'System',
                  description: 'Recommended · follow your phone appearance',
                  isSelected: selectedMode == ThemeMode.system,
                  onTap: () =>
                      unawaited(_selectMode(context, ThemeMode.system)),
                ),
                const SizedBox(height: 12),
                ThemeModeCard(
                  mode: ThemeMode.light,
                  title: 'Light',
                  description: 'Bright canvas with dark foregrounds',
                  isSelected: selectedMode == ThemeMode.light,
                  onTap: () => unawaited(_selectMode(context, ThemeMode.light)),
                ),
                const SizedBox(height: 12),
                ThemeModeCard(
                  mode: ThemeMode.dark,
                  title: 'Dark',
                  description: 'Deep navy surfaces with warm ivory accents',
                  isSelected: selectedMode == ThemeMode.dark,
                  onTap: () => unawaited(_selectMode(context, ThemeMode.dark)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectMode(BuildContext context, ThemeMode mode) async {
    final saved = await BlocProvider.of<ThemeModeCubit>(
      context,
    ).setThemeMode(mode);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Appearance changed for this session, but could not be saved.',
            ),
          ),
        );
    }
  }
}
