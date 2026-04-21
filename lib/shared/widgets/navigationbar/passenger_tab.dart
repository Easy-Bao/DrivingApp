import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PassengerShellLayout extends StatelessWidget {
  final Widget child;
  const PassengerShellLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/passenger/home')) return 0;
    if (location.startsWith('/passenger/activity')) return 1;
    if (location.startsWith('/passenger/favorites')) return 2;
    if (location.startsWith('/passenger/account')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('PassengerHome');
        break;
      case 1:
        context.goNamed('PassengerActivity');
        break;
      case 2:
        context.goNamed('PassengerFavorites');
        break;
      case 3:
        context.goNamed('PassengerAccount');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.outlineBorderColor, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onItemTapped(index, context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: [
            NavigationDestination(
              icon: Icon(
                LucideIcons.house,
                color: AppTheme.unselectedItemColor,
              ),
              selectedIcon: Icon(
                LucideIcons.house,
                color: AppTheme.selectedItemColor,
                size: 26,
                weight: 700,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                LucideIcons.bookmark,
                color: AppTheme.unselectedItemColor,
              ),
              selectedIcon: Icon(
                LucideIcons.bookmark,
                color: AppTheme.selectedItemColor,
                size: 26,
                weight: 700,
              ),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Icon(
                LucideIcons.heart,
                color: AppTheme.unselectedItemColor,
              ),
              selectedIcon: Icon(
                LucideIcons.heart,
                color: AppTheme.selectedItemColor,
                size: 26,
                weight: 700,
              ),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.user, color: AppTheme.unselectedItemColor),
              selectedIcon: Icon(
                LucideIcons.user,
                color: AppTheme.selectedItemColor,
                size: 26,
                weight: 700,
              ),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
