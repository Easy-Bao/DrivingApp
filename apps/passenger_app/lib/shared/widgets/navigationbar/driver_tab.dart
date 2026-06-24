import 'package:passenger_app/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DriverShellLayout extends StatefulWidget {
  final Widget child;
  const DriverShellLayout({super.key, required this.child});

  @override
  State<DriverShellLayout> createState() => _DriverShellLayoutState();
}

class _DriverShellLayoutState extends State<DriverShellLayout> {
  final List<int> _navigationHistory = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIndex = _calcIndex(context);
    if (_navigationHistory.isEmpty) {
      _navigationHistory.add(newIndex);
    } else if (_navigationHistory.last != newIndex) {
      _navigationHistory.add(newIndex);
    }
  }

  int _calcIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/driver/dashboard')) return 0;
    if (loc.startsWith('/driver/earnings')) return 1;
    if (loc.startsWith('/driver/account')) return 2;
    return 0;
  }

  void _onTap(int i, BuildContext ctx) {
    if (i == _calcIndex(ctx)) return;
    _navigateToIndex(i);
  }

  void _navigateToIndex(int index) {
    switch (index) {
      case 0:
        context.goNamed('DriverDashboard');
        break;
      case 1:
        context.goNamed('DriverEarnings');
        break;
      case 2:
        context.goNamed('DriverAccount');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _calcIndex(context);

    return PopScope(
      canPop: _navigationHistory.length <= 1 &&
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
        extendBody: false,
        body: widget.child,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(
                  color: AppTheme.outlineBorderColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _tab(
                  context,
                  LucideIcons.layout_dashboard,
                  'Dashboard',
                  0,
                  sel == 0,
                ),
                _tab(context, LucideIcons.wallet, 'Earnings', 1, sel == 1),
                _tab(context, LucideIcons.user, 'Account', 2, sel == 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext ctx,
    IconData icon,
    String label,
    int idx,
    bool isSel,
  ) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(idx, ctx),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSel
                    ? AppTheme.selectedItemColor
                    : AppTheme.unselectedItemColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                  color: isSel
                      ? AppTheme.selectedItemColor
                      : AppTheme.unselectedItemColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
