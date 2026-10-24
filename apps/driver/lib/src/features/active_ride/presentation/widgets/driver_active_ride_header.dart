import 'package:flutter/material.dart';

class const ActiveRideHeader({
  super.key,
  required this.backButton,
  this.padding = EdgeInsets.zero,
}) extends StatelessWidget {
  final Widget backButton;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(children: [backButton]),
  );
}
