import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverAppearancePage extends StatelessWidget {
  const DriverAppearancePage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppAppearancePage(onBack: onBack ?? () => context.pop());
  }
}
