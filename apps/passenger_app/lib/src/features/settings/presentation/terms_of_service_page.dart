import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppTermsOfServicePage(onBack: onBack ?? () => context.pop());
  }
}
