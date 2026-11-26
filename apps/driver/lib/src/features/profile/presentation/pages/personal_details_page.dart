import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/account_snapshot.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';

class const PersonalDetailsPage({super.key, this.onBack})
    extends StatelessWidget {
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppSecondaryPage(
      title: 'Personal details',
      onBack: onBack ?? () => context.pop(),
      maxWidth: 560,
      child: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, state) {
          final account = state.account;
          final colorScheme = context.colorScheme;
          final hairline = Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          );
          final insetHairline = Divider(
            height: 1,
            thickness: 1,
            indent: 34,
            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360
                  ? AppLayout.pagePadding
                  : AppLayout.pagePaddingWide;
              return ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.xl,
                  horizontalPadding,
                  48,
                ),
                children: [
                  _PersonalDetailsHeader(account: account),
                  const SizedBox(height: AppSpacing.xxxl),
                  if (state.isLoading) ...[
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (state.errorMessage case final errorMessage?) ...[
                    AppErrorBanner(
                      message: errorMessage,
                      onRetry: () =>
                          BlocProvider.of<AccountCubit>(context).load(),
                      onDismiss: () =>
                          BlocProvider.of<AccountCubit>(context).dismissError(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  hairline,
                  _ContactDetailRow(
                    icon: LucideIcons.user_round,
                    label: 'Full name',
                    value: account.name,
                  ),
                  insetHairline,
                  _ContactDetailRow(
                    icon: LucideIcons.phone,
                    label: 'Mobile number',
                    value: account.phone,
                    isVerifiedLocked: true,
                    useTabular: true,
                  ),
                  insetHairline,
                  _ContactDetailRow(
                    icon: LucideIcons.mail,
                    label: 'Email',
                    value: account.email,
                    isVerifiedLocked: true,
                  ),
                  hairline,
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ExcludeSemantics(
                            child: Icon(
                              LucideIcons.lock_keyhole,
                              size: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: Text(
                            'Phone number and email are verified account identifiers and can’t be edited here.',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class const _PersonalDetailsHeader({required this.account})
    extends StatelessWidget {
  final AccountSnapshot account;

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'D';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Column(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(account.name),
              style: textStyles.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your contact details',
          textAlign: TextAlign.center,
          style: textStyles.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class const _ContactDetailRow({
  required this.icon,
  required this.label,
  required this.value,
  this.isVerifiedLocked = false,
  this.useTabular = false,
}) extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isVerifiedLocked;
  final bool useTabular;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final isEmpty = value.trim().isEmpty;
    final baseValueStyle =
        (useTabular ? textStyles.bodyLarge?.tabular : textStyles.bodyLarge)
            ?.copyWith(
              fontWeight: isVerifiedLocked || isEmpty
                  ? FontWeight.w500
                  : FontWeight.w600,
              color: isVerifiedLocked || isEmpty
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ExcludeSemantics(
              child: Icon(
                icon,
                size: 18,
                color: isVerifiedLocked
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.72)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: textStyles.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isVerifiedLocked) ...[
                      const SizedBox(width: 6),
                      ExcludeSemantics(
                        child: Icon(
                          LucideIcons.lock,
                          size: 11,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(isEmpty ? 'Not provided' : value, style: baseValueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
