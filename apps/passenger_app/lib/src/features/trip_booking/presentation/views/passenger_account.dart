import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/core/themes/app_themes.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/profile/profile_cubit.dart';

/// Screen displaying the passenger's account menu options and syncing profile details.
/// Delegates data retrieval and persistence entirely to the [ProfileCubit] state machine.
class PassengerAccountScreen extends StatefulWidget {
  const PassengerAccountScreen({super.key});

  @override
  State<PassengerAccountScreen> createState() => _PassengerAccountScreenState();
}

class _PassengerAccountScreenState extends State<PassengerAccountScreen> {
  List<_AccountMenuItem> _buildActivityItems(BuildContext context) {
    return [
      _AccountMenuItem(
        icon: LucideIcons.history,
        title: 'Ride History',
        subtitle: 'View your past trips',
        onTap: () => context.pushNamed('RideHistory'),
      ),
    ];
  }

  List<_AccountMenuItem> _buildPersonalItems(BuildContext context) {
    return [
      _AccountMenuItem(
        icon: LucideIcons.user,
        title: 'Profile Info',
        subtitle: 'Update name and details',
        onTap: () async {
          await context.pushNamed('ProfileInfo');
          if (context.mounted) {
            unawaited(BlocProvider.of<ProfileCubit>(context).loadProfile());
          }
        },
      ),
    ];
  }

  List<_AccountMenuItem> _buildSupportItems(BuildContext context) {
    return [
      _AccountMenuItem(
        icon: LucideIcons.message_circle_question_mark,
        title: 'Help Center',
        subtitle: 'Get support and FAQs',
        onTap: () => context.pushNamed('HelpCenter'),
      ),
      _AccountMenuItem(
        icon: LucideIcons.info,
        title: 'About BaoRide',
        subtitle: 'Version 1.0.0',
        onTap: () {},
      ),
    ];
  }

  Widget _buildProfileHeader(ProfileState state) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSide, width: 2),
            ),
            child: const Icon(
              LucideIcons.user,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.name.isNotEmpty ? state.name : '—',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.phone.isNotEmpty ? state.phone : '—',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              state.email,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor.withValues(alpha: 0.45),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, _AccountMenuItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Icon(item.icon, size: 20, color: AppTheme.primaryColor),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryColor,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevron_right,
        size: 16,
        color: AppTheme.primaryColor,
      ),
      onTap: item.onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) {
        final cubit = getIt<ProfileCubit>();
        unawaited(cubit.loadProfile());
        return cubit;
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildProfileHeader(state),
                    const SizedBox(height: 40),
                    _buildSectionTitle('Activity'),
                    ..._buildActivityItems(
                      context,
                    ).map((item) => _buildAccountTile(context, item)),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Personal'),
                    ..._buildPersonalItems(
                      context,
                    ).map((item) => _buildAccountTile(context, item)),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Support'),
                    ..._buildSupportItems(
                      context,
                    ).map((item) => _buildAccountTile(context, item)),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
