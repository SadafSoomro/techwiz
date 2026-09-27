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
        return Image.asset(
          'assets/images/fandom_logo.jpg',
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFF59E0B)],
              ).createShader(bounds),
              child: Text(
                'FANDOM VERSE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: height * 0.28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
