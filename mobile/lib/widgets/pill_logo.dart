import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';

class PillLogo extends StatelessWidget {
  const PillLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.5,
            child: Container(
              width: size * 0.55,
              height: size * 0.22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentYellow, Color(0xFFFFE08A)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.35,
            child: Container(
              width: size * 0.55,
              height: size * 0.22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.danger.withOpacity(0.9), AppColors.danger],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
