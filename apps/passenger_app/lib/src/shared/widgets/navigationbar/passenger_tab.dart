import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/passenger_home_cubit.dart';
import 'package:shared_ui/shared_ui.dart';

//TODO: Improve the menu
class PassengerShellLayout extends StatefulWidget {
  final Widget child;
  const PassengerShellLayout({super.key, required this.child});

  @override
  State<PassengerShellLayout> createState() => _PassengerShellLayoutState();
}

class _PassengerShellLayoutState extends State<PassengerShellLayout>
    with SingleTickerProviderStateMixin {
  final List<int> _navigationHistory = [];

  bool _rideMenuOpen = false;

  late final AnimationController _rideMenuController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  late final Animation<double> _rideMenuHeight = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 0.55,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.55,
        end: 0.85,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.85,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
  ]).animate(_rideMenuController);

  late final Animation<double> _rideMenuFade = CurvedAnimation(
    parent: _rideMenuController,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    reverseCurve: Curves.easeIn,
  );

  @override
  void dispose() {
    _rideMenuController.dispose();
    super.dispose();
  }

  void _toggleRideMenu() {
    setState(() => _rideMenuOpen = !_rideMenuOpen);
    if (_rideMenuOpen) {
      unawaited(_rideMenuController.forward(from: 0));
    } else {
      unawaited(_rideMenuController.reverse());
    }
  }

  void _closeRideMenu() {
    if (!_rideMenuOpen) return;
    setState(() => _rideMenuOpen = false);
    unawaited(_rideMenuController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final sel = _calculateSelectedIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop:
          !_rideMenuOpen &&
          _navigationHistory.length <= 1 &&
          _navigationHistory.isNotEmpty &&
          _navigationHistory.last == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_rideMenuOpen) {
          _closeRideMenu();
          return;
        }
        if (_navigationHistory.length > 1) {
          setState(() {
            _navigationHistory.removeLast();
            final previousIndex = _navigationHistory.last;
            _navigateToIndex(previousIndex);
          });
        } else {
          setState(() {
            _navigationHistory.clear();
            _navigationHistory.add(0);
            _navigateToIndex(0);
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            widget.child,

            // Dim backdrop while the ride menu is open.
            IgnorePointer(
              ignoring: !_rideMenuOpen,
              child: AnimatedOpacity(
                opacity: _rideMenuOpen ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _closeRideMenu,
                  child: Container(color: Colors.black.withValues(alpha: 0.32)),
                ),
              ),
            ),

            // Ride options menu, anchored above the FAB, same width as the
            // FAB itself (64), revealing from 0 height to full height.
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + 12 + 58 + 12,
              child: AnimatedBuilder(
                animation: _rideMenuController,
                builder: (context, child) {
                  return IgnorePointer(
                    ignoring: !_rideMenuOpen,
                    child: Opacity(
                      opacity: _rideMenuFade.value,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          heightFactor: _rideMenuHeight.value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: _RideOptionsMenu(
                  onShareRide: () {
                    _closeRideMenu();
                    String? address;
                    try {
                      address = BlocProvider.of<PassengerHomeCubit>(
                        context,
                      ).state.currentAddress;
                    } catch (_) {}
                    unawaited(
                      context.pushNamed(
                        'SearchDestination',
                        queryParameters: {
                          'rideType': 'Share Ride',
                          'pickupAddress': address,
                        },
                      ),
                    );
                  },
                  onSoloRide: () {
                    _closeRideMenu();
                    String? address;
                    try {
                      address = BlocProvider.of<PassengerHomeCubit>(
                        context,
                      ).state.currentAddress;
                    } catch (_) {}
                    unawaited(
                      context.pushNamed(
                        'SearchDestination',
                        queryParameters: {
                          'rideType': 'Solo Ride',
                          'pickupAddress': address,
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 12),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(29),
              border: Border.all(
                color: AppTheme.outlineBorderColor.withValues(
                  alpha: 0.1,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabItem(
                  context,
                  icon: LucideIcons.house,
                  label: 'Home',
                  index: 0,
                  isSelected: sel == 0,
                ),
                _buildTabItem(
                  context,
                  icon: LucideIcons.history,
                  label: 'Activity',
                  index: 1,
                  isSelected: sel == 1,
                ),
                _buildCenterFab(),
                _buildTabItem(
                  context,
                  icon: LucideIcons.user,
                  label: 'Account',
                  index: 2,
                  isSelected: sel == 2,
                ),
                _buildTabItem(
                  context,
                  icon: LucideIcons.message_circle_question_mark,
                  label: 'Help',
                  index: 3,
                  isSelected: sel == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIndex = _calculateSelectedIndex(context);
    if (_navigationHistory.isEmpty) {
      _navigationHistory.add(newIndex);
    } else if (_navigationHistory.last != newIndex) {
      _navigationHistory.add(newIndex);
    }
  }

  Widget _buildTabItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final color = isSelected
        ? AppTheme.selectedItemColor
        : AppTheme.unselectedItemColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index, context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFab() {
    return GestureDetector(
      onTap: _toggleRideMenu,
      child: AnimatedRotation(
        turns: _rideMenuOpen ? 0.125 : 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                AppTheme.primaryColor,
                Color(0xFF2C3E50),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.plus,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final String location = state.uri.path;
    final String? routeName = state.topRoute?.name;

    if (routeName != null) {
      if (routeName.contains('Home')) return 0;
      if (routeName.contains('Activity')) return 1;
      if (routeName.contains('Account')) return 2;
      if (routeName.contains('Help')) return 3;
    }

    if (location.contains('/home')) return 0;
    if (location.contains('/activity')) return 1;
    if (location.contains('/account')) return 2;
    if (location.contains('/help')) return 3;

    return 0;
  }

  void _navigateToIndex(int index) {
    switch (index) {
      case 0:
        context.goNamed('PassengerHome');
        break;
      case 1:
        context.goNamed('PassengerActivity');
        break;
      case 2:
        context.goNamed('PassengerAccount');
        break;
      case 3:
        context.goNamed('PassengerHelp');
        break;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    if (_rideMenuOpen) _closeRideMenu();
    if (index == _calculateSelectedIndex(context)) return;
    _navigateToIndex(index);
  }
}

class _RideOptionsMenu extends StatelessWidget {
  final VoidCallback onShareRide;
  final VoidCallback onSoloRide;

  const _RideOptionsMenu({required this.onShareRide, required this.onSoloRide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outlineBorderColor.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RideOptionTile(
            icon: LucideIcons.users,
            label: 'Share Ride',
            onTap: onShareRide,
          ),
          const SizedBox(height: 4),
          _RideOptionTile(
            icon: LucideIcons.user,
            label: 'Solo Ride',
            onTap: onSoloRide,
          ),
        ],
      ),
    );
  }
}

class _RideOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RideOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
