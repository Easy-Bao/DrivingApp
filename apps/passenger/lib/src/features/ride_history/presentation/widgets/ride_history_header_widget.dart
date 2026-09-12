import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class const RideHistoryHeaderWidget({required this.subtitle, super.key})
    extends StatelessWidget {
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppPageHeader(title: 'Activity', subtitle: subtitle);
  }
}
