import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

class const AppTermsOfServicePage({super.key, required this.onBack})
    extends StatelessWidget {
  final VoidCallback onBack;

  static const _sections = <({String title, String body})>[
    (
      title: 'Using EasyRide',
      body: 'Use accurate account and trip information, follow applicable laws, and treat everyone involved in a ride respectfully.',
    ),
    (
      title: 'Ride requests and payments',
      body: 'Review trip, fare, and payment details before confirming. Charges and adjustments shown in the app apply to the completed ride.',
    ),
    (
      title: 'Safety and availability',
      body: 'Do not use EasyRide for emergencies. Service availability can vary by location, network access, driver supply, and operational conditions.',
    ),
    (
      title: 'Account responsibility',
      body: 'Keep your sign-in details secure and contact support if you believe your account or ride information has been misused.',
    ),
    (
      title: 'Changes to the service',
      body: 'Features may change as EasyRide improves. Material terms should be presented in the app before they take effect.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppSecondaryPage(
      title: 'Terms of Service',
      onBack: onBack,
      maxWidth: 600,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 360
              ? AppLayout.pagePadding
              : AppLayout.pagePaddingWide;
          return SelectionArea(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                48,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'EasyRide Terms of Service',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  'Effective for this app release',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
                for (var index = 0; index < _sections.length; index++) ...[
                  _TermsSection(
                    number: (index + 1).toString().padLeft(2, '0'),
                    title: _sections[index].title,
                    body: _sections[index].body,
                  ),
                  if (index != _sections.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class const _TermsSection({
  required this.number,
  required this.title,
  required this.body,
}) extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ExcludeSemantics(
              child: Text(
                number,
                style: textTheme.labelSmall?.tabular.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  label: '$number. $title',
                  child: ExcludeSemantics(
                    child: Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
