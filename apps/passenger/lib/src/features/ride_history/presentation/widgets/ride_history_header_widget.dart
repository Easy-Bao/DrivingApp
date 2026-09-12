import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class const RideHistoryHeaderWidget({
  required this.subtitle,
  this.title = 'Activity',
  super.key,
}) extends StatelessWidget {
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return EasyRidePageHeader(title: title, subtitle: subtitle);
  }
}
