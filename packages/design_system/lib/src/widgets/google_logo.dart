import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class const GoogleLogo({super.key, this.size = 22}) extends StatelessWidget {
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/google.svg',
      package: 'design_system',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: 'Google',
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.g_mobiledata,
        size: size,
        color: Theme.of(context).colorScheme.onSurface,
        semanticLabel: 'Google',
      ),
    );
  }
}
