import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/inbox/presentation/formatters/inbox_presenter.dart';

class InboxEmptyState extends StatelessWidget {
  const InboxEmptyState({
    super.key,
    this.isGuest = false,
    this.filter = InboxFilter.all,
    this.onResetFilter,
    this.bottomPadding = 0,
  });

  final bool isGuest;
  final InboxFilter filter;
  final VoidCallback? onResetFilter;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    final IconData icon;
    final String title;
    final String description;

    if (isGuest) {
      icon = LucideIcons.mail;
      title = 'Stay up to date';
      description = 'Sign in or create an account to receive ride updates and account notifications.';
    } else {
      switch (filter) {
        case InboxFilter.all:
          icon = LucideIcons.mail;
          title = 'No notifications yet';
          description = "We'll notify you about rides and account activity.";
        case InboxFilter.unread:
          icon = LucideIcons.check;
          title = 'All caught up';
          description = 'You have read all of your notifications.';
        case InboxFilter.messages:
          icon = LucideIcons.message_circle;
          title = 'No messages yet';
          description = 'Messages from your driver will appear here.';
        case InboxFilter.rides:
          icon = LucideIcons.receipt;
          title = 'No ride updates yet';
          description = 'Ride updates and receipts will appear here.';
      }
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xxl,
          AppSpacing.xxl,
          AppSpacing.xxl + bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 22,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: textStyles.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.48,
                ),
              ),
            ),
            if (!isGuest &&
                filter != InboxFilter.all &&
                onResetFilter != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                key: const ValueKey<String>('inbox-reset-filter'),
                onPressed: onResetFilter,
                style:
                    TextButton.styleFrom(
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.focused)) {
                          return colorScheme.primary.withValues(alpha: 0.12);
                        }
                        return Colors.transparent;
                      }),
                    ),
                child: const Text('Show all'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
