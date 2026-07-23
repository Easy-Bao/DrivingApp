import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/profile_routes.dart';
import 'package:passenger_app/src/features/settings/settings_routes.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_ui/shared_ui.dart';

///TODO: Convert into account screen rather than PassengerAccountScreen
class PassengerAccountScreen extends StatefulWidget {
  const PassengerAccountScreen({super.key});

  @override
  State<PassengerAccountScreen> createState() => _PassengerAccountScreenState();
}

class _PassengerAccountScreenState extends State<PassengerAccountScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) {
        final cubit = Modular.get<ProfileCubit>();
        unawaited(cubit.loadProfile());
        return cubit;
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final initials = _getInitials(state.name);

          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 0.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppTheme.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFF8A4F35),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.name.isNotEmpty ? state.name : 'User',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.phone.isNotEmpty
                                    ? state.phone
                                    : 'No Phone Number',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.pencil,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          onPressed: () async {
                            await context.pushNamed(ProfileRoutes.profileInfo);
                            if (context.mounted) {
                              unawaited(
                                BlocProvider.of<ProfileCubit>(
                                  context,
                                ).loadProfile(),
                              );
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('PLACES AND SAFETY'),

                    const SizedBox(height: 12),
                    _buildMenuTile(
                      icon: LucideIcons.map_pin,
                      title: 'Saved places',
                      onTap: () => context.pushNamed(ProfileRoutes.help),
                    ),
                    _buildMenuTile(
                      icon: LucideIcons.shield,
                      title: 'Safety center',
                      onTap: () {
                        CustomToast.show(
                          context,
                          'Safety center is coming soon.',
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    _buildSectionTitle('SUPPORT'),
                    const SizedBox(height: 12),
                    _buildMenuTile(
                      icon: LucideIcons.message_circle_question_mark,
                      title: 'Help center',
                      onTap: () => context.pushNamed(ProfileRoutes.helpCenter),
                    ),
                    _buildMenuTile(
                      icon: LucideIcons.settings,
                      title: 'Settings',
                      onTap: () => context.pushNamed(SettingsRoutes.settings),
                    ),

                    const SizedBox(height: 48),

                    InkWell(
                      onTap: () => _handleLogout(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.1),
                            width: 1.0,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              LucideIcons.log_out,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Log out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: AppTheme.neutralColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderSide.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _handleLogout(BuildContext context) async {
    await Modular.get<PassengerSessionService>().clearSession();
    if (context.mounted) {
      context.go('/');
    }
  }
}
