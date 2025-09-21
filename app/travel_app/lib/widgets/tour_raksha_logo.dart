import 'package:flutter/material.dart';

class TourRakshaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? backgroundColor;

  const TourRakshaLogo({
    super.key,
    this.size = 180,
    this.showText = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.15,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor ?? const Color(0xFF1E40AF), // Professional blue
            backgroundColor?.withOpacity(0.8) ??
                const Color(0xFF1E3A8A), // Darker blue
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.11),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: size * 0.14,
            offset: Offset(0, size * 0.08),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.white, width: size * 0.017),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shield background pattern
          Container(
            width: size * 0.78,
            height: size * 0.89,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.08),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),

          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo image
              Image.asset(
                'assets/TourRakshaLogo.png',
                width: size * 0.7,
                height: size * 0.7,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),

              if (showText) ...[
                SizedBox(height: size * 0.04),

                // App name
                Text(
                  'TourRaksha',
                  style: TextStyle(
                    color: const Color(0xFF0891B2), // Teal
                    fontSize: size * 0.13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                SizedBox(height: size * 0.02),

                // Hindi subtitle
                Text(
                  'रक्षा',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: size * 0.09,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ],
          ),

          // Decorative corner elements
          Positioned(
            top: size * 0.08,
            right: size * 0.08,
            child: Container(
              width: size * 0.06,
              height: size * 0.06,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: size * 0.08,
            left: size * 0.08,
            child: Container(
              width: size * 0.04,
              height: size * 0.04,
              decoration: BoxDecoration(
                color: const Color(0xFF0891B2).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
