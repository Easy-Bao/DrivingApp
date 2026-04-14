import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PassengerShellLayout extends StatelessWidget {
  final Widget child;

  const PassengerShellLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final String location = state.uri.path;

    if (location.contains('home')) return 0;
    if (location.contains('order')) return 1;
    if (location.contains('favorites')) return 2;
    if (location.contains('account')) return 3;

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('PassengerHome');
        break;
      case 1:
        context.goNamed('PassengerOrder');
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
    return Scaffold(
      body: child,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              top: BorderSide(color: AppTheme.outlineBorderColor, width: 1.0),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onItemTapped(index, context),
            backgroundColor:
                Colors.transparent, // Lets the container's color show through
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: AppTheme.selectedItemColor,
            unselectedItemColor: AppTheme.unselectedItemColor,
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(LucideIcons.house),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(LucideIcons.bookmark),
                ),
                label: 'Order',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(LucideIcons.heart),
                ),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(LucideIcons.user),
                ),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
