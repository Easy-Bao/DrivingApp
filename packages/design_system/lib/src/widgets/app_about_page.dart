import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:design_system/src/theme/design_system_context.dart';
import 'package:design_system/src/tokens/radius.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:design_system/src/widgets/easy_ride_layout.dart';

/// A role-configured EasyRide about page with a real licenses destination.
class const AppAboutPage({
  super.key,
  required this.applicationName,
  required this.applicationVersion,
  required this.description,
  required this.icon,
  required this.onBack,
  required this.onLicensesTap,
}) extends StatelessWidget {
  final String applicationName;
  final String applicationVersion;
  final String description;
  final IconData icon;
  final VoidCallback onBack;
  final VoidCallback onLicensesTap;

  @override
  Widget build(BuildContext context) {
    return EasyRideSecondaryPage(
      title: 'About EasyRide',
      onBack: onBack,
      maxWidth: 600,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(EasyRideRadius.xl),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 36,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: EasyRideSpacing.lg),
          Text(
            applicationName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            'Version $applicationVersion',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EasyRideSpacing.xxl),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: EasyRideSpacing.xxl),
          Material(
            color: context.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EasyRideRadius.lg),
              side: BorderSide(color: context.colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              minVerticalPadding: 14,
              leading: const Icon(LucideIcons.code_xml),
              title: const Text('Open-source licenses'),
              subtitle: const Text('Libraries used to build EasyRide'),
              trailing: const Icon(LucideIcons.chevron_right, size: 19),
              onTap: onLicensesTap,
            ),
          ),
        ],
      ),
    );
  }
}
