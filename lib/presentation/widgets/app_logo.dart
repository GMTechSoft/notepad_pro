import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.shield_moon,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
