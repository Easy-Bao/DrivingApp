import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

// TODO: Refactor this to use a more dynamic approach, such as using a list of routes and icons to generate the navigation bar items, instead of hardcoding each case in the _onItemTapped method. This will make it easier to maintain and extend the navigation bar in the future.
class PassengerShellLayout extends StatelessWidget {
  final Widget child;
  const PassengerShellLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/passenger/home')) return 0;
    if (location.startsWith('/passenger/activity')) return 1;
    if (location.startsWith('/passenger/account')) return 2;
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
        context.goNamed('PassengerAccount');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppTheme.outlineBorderColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: Colors.transparent,
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
                        size: 24,
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
                        size: 24,
                      ),
                      label: 'Activity',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        LucideIcons.user,
                        color: AppTheme.unselectedItemColor,
                      ),
                      selectedIcon: Icon(
                        LucideIcons.user,
                        color: AppTheme.selectedItemColor,
                        size: 24,
                      ),
                      label: 'Account',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.navigation,
                  color: AppTheme.neutralColor,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
