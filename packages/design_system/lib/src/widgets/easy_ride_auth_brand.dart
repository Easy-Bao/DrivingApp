import 'package:flutter/material.dart';

/// Compact brand mark for authentication toolbars.
class const EasyRideAuthBrand({super.key, this.size = 40})
    extends StatelessWidget {
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/applogo.png',
      package: 'design_system',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'EasyRide',
    );
  }
}
