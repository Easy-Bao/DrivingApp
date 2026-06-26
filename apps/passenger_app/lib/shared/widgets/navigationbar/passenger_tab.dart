import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/core/themes/app_themes.dart';

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
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppTheme.outlineBorderColor.withValues(
                        alpha: 0.16,
                      ),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildTabItem(
                        context,
                        icon: LucideIcons.house,
                        index: 0,
                        isSelected: sel == 0,
                      ),
                      _buildTabItem(
                        context,
                        icon: LucideIcons.bookmark,
                        index: 1,
                        isSelected: sel == 1,
                      ),
                      _buildTabItem(
                        context,
                        icon: LucideIcons.user,
                        index: 2,
                        isSelected: sel == 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final result = await context.pushNamed('MapPin');
                  if (!context.mounted) return;
                  if (result != null && result is PlaceModel) {
                    await context.pushNamed(
                      'DestinationPreview',
                      extra: result,
                    );
                  }
                },
                child: Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
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
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index, context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? AppTheme.selectedItemColor
                      : AppTheme.unselectedItemColor,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: isSelected ? 4 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.selectedItemColor,
                  borderRadius: BorderRadius.circular(2),
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
      if (routeName.contains('Home')) return 0;
      if (routeName.contains('Activity')) return 1;
      if (routeName.contains('Account')) return 2;
    }

    if (location.contains('/home')) return 0;
    if (location.contains('/activity')) return 1;
    if (location.contains('/account')) return 2;

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
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == _calculateSelectedIndex(context)) return;
    _navigateToIndex(index);
  }
}
