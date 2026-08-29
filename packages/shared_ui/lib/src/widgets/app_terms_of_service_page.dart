import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/src/theme/easy_ride_theme_context.dart';

/// Shared service terms used by the passenger and driver clients.
class AppTermsOfServicePage extends StatelessWidget {
  const AppTermsOfServicePage({super.key, required this.onBack});

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
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
            children: [
              Text(
                'BaoRide Terms of Service',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Effective for this app release',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const _TermsSection(
                title: 'Using BaoRide',
                body:
                    'Use accurate account and trip information, follow applicable laws, and treat everyone involved in a ride respectfully.',
              ),
              const _TermsSection(
                title: 'Ride requests and payments',
                body:
                    'Review trip, fare, and payment details before confirming. Charges and adjustments shown in the app apply to the completed ride.',
              ),
              const _TermsSection(
                title: 'Safety and availability',
                body:
                    'Do not use BaoRide for emergencies. Service availability can vary by location, network access, driver supply, and operational conditions.',
              ),
              const _TermsSection(
                title: 'Account responsibility',
                body:
                    'Keep your sign-in details secure and contact support if you believe your account or ride information has been misused.',
              ),
              const _TermsSection(
                title: 'Changes to the service',
                body:
                    'Features may change as BaoRide improves. Material terms should be presented in the app before they take effect.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 7),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
