import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/performance/performance_routes.dart';
import 'package:driver/src/features/profile/domain/entities/account_snapshot.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver/src/features/profile/presentation/widgets/account_profile_header.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.pageMaxWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360
                    ? AppLayout.pagePadding
                    : AppLayout.pagePaddingWide;
                return BlocBuilder<AccountCubit, AccountState>(
                  builder: (context, state) => SingleChildScrollView(
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
                        AccountProfileHeader(
                          account: state.account,
                          onTap: () => unawaited(
                            context.pushNamed(ProfileRoutes.personalDetails),
                          ),
                        ),
                        if (state.isLoading) ...[
                          const SizedBox(height: AppSpacing.md),
                          const LinearProgressIndicator(minHeight: 2),
                        ],
                        if (state.errorMessage case final errorMessage?) ...[
                          const SizedBox(height: AppSpacing.lg),
                          AppErrorBanner(
                            message: errorMessage,
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
                              onTap: () =>
                                  unawaited(_openVehicleInformation(context)),
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openVehicleInformation(BuildContext context) async {
    final accountCubit = BlocProvider.of<AccountCubit>(context);
    final updated = await context.pushNamed<bool>(
      ProfileRoutes.vehicleInformation,
    );
    if (!context.mounted) return;
    if (updated == true) {
      AppSnackBar.show(context, 'Vehicle information updated.');
      return;
    }
    unawaited(accountCubit.load());
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

  Future<void> _handleLogout(BuildContext context) async {
    if (_isLoggingOut) return;
    final confirmed = await _confirmLogout(context);
    if (!confirmed || !mounted || !context.mounted) return;
    setState(() => _isLoggingOut = true);

    try {
      await widget.onLogout();
      if (context.mounted) context.goNamed(AuthRoutes.signin);
    } catch (error) {
      debugPrint('Unable to log out driver: $error');
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      if (context.mounted) {
        AppSnackBar.show(
          context,
          'Unable to log out right now. Please try again.',
          isError: true,
        );
      }
    }
  }

  Future<bool> _confirmLogout(BuildContext context) {
    return showAppConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again before going online or accepting trips.',
      confirmLabel: 'Log out',
      cancelLabel: 'Cancel',
      icon: LucideIcons.log_out,
      tone: AppConfirmDialogTone.destructive,
      isDestructive: true,
    );
  }
}
