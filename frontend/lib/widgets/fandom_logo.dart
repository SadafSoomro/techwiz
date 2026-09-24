import 'package:flutter/material.dart';

class FandomLogoWidget extends StatelessWidget {
  final double height;

  const FandomLogoWidget({super.key, this.height = 110});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/fandom_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();
      },
    );
  }
}
