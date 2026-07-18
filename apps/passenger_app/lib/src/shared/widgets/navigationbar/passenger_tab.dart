import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/booking/trip_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class PassengerShellLayout extends StatefulWidget {
  final Widget child;
  const PassengerShellLayout({super.key, required this.child});

  @override
  State<PassengerShellLayout> createState() => _PassengerShellLayoutState();
}

class _PassengerShellLayoutState extends State<PassengerShellLayout> {
  final List<int> _navigationHistory = [];

  @override
  Widget build(BuildContext context) {
    final sel = _calculateSelectedIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop:
          _navigationHistory.length <= 1 &&
          _navigationHistory.isNotEmpty &&
          _navigationHistory.last == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
        body: widget.child,
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
                _buildTabItem(
                  context,
                  icon: LucideIcons.mail,
                  label: 'Inbox',
                  index: 2,
                  isSelected: sel == 2,
                ),
                _buildTabItem(
                  context,
                  icon: LucideIcons.user,
                  label: 'Profile',
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

  int _calculateSelectedIndex(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final String location = state.uri.path;
    final String? routeName = state.topRoute?.name;

    if (routeName != null) {
      if (routeName == TripRoutes.passengerHome) {
        return 0;
      }
      if (routeName == TripRoutes.passengerActivity) {
        return 1;
      }
      if (routeName == TripRoutes.inbox) {
        return 2;
      }
      if (routeName == TripRoutes.passengerAccount ||
          routeName == TripRoutes.passengerHelp) {
        return 3;
      }
    }

    if (location.contains('/home')) {
      return 0;
    }
    if (location.contains('/activity')) {
      return 1;
    }
    if (location.contains('/inbox')) {
      return 2;
    }
    if (location.contains('/account') || location.contains('/help')) {
      return 3;
    }

    return 0;
  }

  void _navigateToIndex(int index) {
    switch (index) {
      case 0:
        context.goNamed(TripRoutes.passengerHome);
        break;
      case 1:
        context.goNamed(TripRoutes.passengerActivity);
        break;
      case 2:
        context.goNamed(TripRoutes.inbox);
        break;
      case 3:
        context.goNamed(TripRoutes.passengerAccount);
        break;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == _calculateSelectedIndex(context)) return;
    _navigateToIndex(index);
  }
}
