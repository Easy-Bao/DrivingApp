import 'package:BaoRide/core/themes/app_themes.dart';
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
  int _calcIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/driver/dashboard')) return 0;
    if (loc.startsWith('/driver/earnings')) return 1;
    if (loc.startsWith('/driver/account')) return 2;
    return 0;
  }

  void _onTap(int i, BuildContext ctx) {
    switch (i) {
      case 0:
        ctx.goNamed('DriverDashboard');
        break;
      case 1:
        ctx.goNamed('DriverEarnings');
        break;
      case 2:
        ctx.goNamed('DriverAccount');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _calcIndex(context);
    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
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
          child: Row(
            children: [
              _tab(context, LucideIcons.layout_dashboard, 0, sel == 0),
              _tab(context, LucideIcons.wallet, 1, sel == 1),
              _tab(context, LucideIcons.user, 2, sel == 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext ctx, IconData icon, int idx, bool isSel) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(idx, ctx),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSel
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSel
                  ? AppTheme.selectedItemColor
                  : AppTheme.unselectedItemColor,
            ),
          ),
        ),
      ),
    );
  }
}
