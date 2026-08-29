import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/settings/settings_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class AboutBaoRidePage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onLicensesTap;

  const AboutBaoRidePage({super.key, this.onBack, this.onLicensesTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack ?? () => context.pop(),
          icon: const Icon(LucideIcons.arrow_left),
        ),
        title: const Text('About BaoRide'),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.car_front,
                    size: 36,
                    color: context.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'BaoRide Passenger',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                'Version 1.0.0',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'BaoRide connects passengers with nearby drivers and keeps pickup, trip, and payment details in one focused experience.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Material(
                color: context.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: context.colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minVerticalPadding: 14,
                  leading: const Icon(LucideIcons.code_xml),
                  title: const Text('Open-source licenses'),
                  subtitle: const Text('Libraries used to build BaoRide'),
                  trailing: const Icon(LucideIcons.chevron_right, size: 19),
                  onTap:
                      onLicensesTap ??
                      () => context.pushNamed(SettingsRoutes.licenses),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
