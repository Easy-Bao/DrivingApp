import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class DriverTermsOfServicePage extends StatelessWidget {
  const DriverTermsOfServicePage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppTermsOfServicePage(onBack: onBack ?? () => context.pop());
  }
}
