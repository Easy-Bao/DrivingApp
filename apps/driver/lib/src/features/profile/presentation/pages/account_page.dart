import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/performance/performance_routes.dart';
import 'package:driver/src/features/profile/domain/entities/account_snapshot.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver/src/features/profile/profile_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';

class const AccountPage({super.key, required this.onLogout})
    extends StatefulWidget {
  final Future<void> Function() onLogout;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) => Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.pageMaxWidth,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? AppLayout.pagePadding
                      : AppLayout.pagePaddingWide;
                  return SingleChildScrollView(
                    key: const ValueKey<String>('driver-account-scroll'),
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.sm,
                      horizontalPadding,
                      AppSpacing.xxxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppPageHeader(title: 'Account'),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildProfileSummary(context, state.account),
                        if (state.isLoading) ...[
                          const SizedBox(height: AppSpacing.md),
                          const LinearProgressIndicator(minHeight: 2),
                        ],
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          AppErrorBanner(
                            message: state.errorMessage!,
                            onRetry: () => unawaited(
                              BlocProvider.of<AccountCubit>(context).load(),
                            ),
                            onDismiss: () =>
                                BlocProvider.of<AccountCubit>(context)
                                    .dismissError(),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: context.colorScheme.outlineVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppSettingsSection(
                          label: 'Driver details',
                          children: [
                            AppSettingsNavigationTile(
                              icon: LucideIcons.car_front,
                              title: 'Vehicle information',
                              subtitle: _vehicleSummary(state.account),
                              onTap: () => unawaited(
                                _openEditableDestination(
                                  context,
                                  ProfileRoutes.vehicleInformation,
                                ),
                              ),
                            ),
                            AppSettingsNavigationTile(
                              icon: LucideIcons.trending_up,
                              title: 'Performance',
                              subtitle: 'Ratings, trips, and earnings',
                              onTap: () => context.pushNamed(
                                PerformanceRoutes.performance,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        _buildLogoutButton(context),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context, AccountSnapshot account) {
    final displayName = account.name.isEmpty ? 'Driver' : account.name;
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Semantics(
      button: true,
      label: '$displayName. View personal details',
      child: InkWell(
        key: const ValueKey<String>('driver-profile-summary'),
        borderRadius: BorderRadius.circular(AppRadius.md),
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
        onTap: () => unawaited(
          _openEditableDestination(context, ProfileRoutes.personalDetails),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  key: const ValueKey<String>('driver-profile-avatar'),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getInitials(displayName),
                    style: textStyles.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyles.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      account.phone.isEmpty
                          ? 'Add your mobile number'
                          : account.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyles.bodyMedium?.tabular.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Personal details',
                      style: textStyles.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.chevron_right,
                  size: 17,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditableDestination(
    BuildContext context,
    String routeName,
  ) async {
    final accountCubit = BlocProvider.of<AccountCubit>(context);
    await context.pushNamed(routeName);
    if (context.mounted) unawaited(accountCubit.load());
  }

  String _vehicleSummary(AccountSnapshot account) {
    final vehicle = account.vehicleType.trim();
    final plate = account.plateNumber.trim();
    if (vehicle.isEmpty && plate.isEmpty) {
      return 'No registered vehicle information';
    }
    if (vehicle.isEmpty) return 'Plate number $plate';
    if (plate.isEmpty) return vehicle;
    return '$vehicle · Plate $plate';
  }

  Widget _buildLogoutButton(BuildContext context) {
    final colorScheme = context.colorScheme;
    final buttonStyle =
        OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return colorScheme.error.withValues(alpha: 0.12);
            }
            return Colors.transparent;
          }),
        );

    return SizedBox(
      key: const ValueKey<String>('driver-account-logout'),
      height: AppSize.controlHeight,
      width: double.infinity,
      child: _isLoggingOut
          ? OutlinedButton(
              onPressed: null,
              style: buttonStyle,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.error,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              style: buttonStyle,
              icon: const Icon(LucideIcons.log_out, size: 17),
              label: const Text('Log out'),
            ),
    );
  }

  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'D';
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await widget.onLogout();
      if (context.mounted) context.goNamed(AuthRoutes.signin);
    } catch (error) {
      debugPrint('Unable to log out driver: $error');
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
    }
  }
}
