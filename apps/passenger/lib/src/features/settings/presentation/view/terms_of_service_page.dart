import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class const TermsOfServicePage({super.key, this.onBack})
    extends StatelessWidget {
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppTermsOfServicePage(onBack: onBack ?? () => context.pop());
  }
}
