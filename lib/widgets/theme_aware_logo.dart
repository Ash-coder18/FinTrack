import 'package:flutter/material.dart';

class ThemeAwareLogo extends StatelessWidget {
  final double height;
  
  const ThemeAwareLogo({super.key, this.height = 36.0});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String imagePath = isDark 
        ? 'assets/icon/logo_dark.png' 
        : 'assets/icon/logo_light.png';
        
    return Image.asset(
      imagePath,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
