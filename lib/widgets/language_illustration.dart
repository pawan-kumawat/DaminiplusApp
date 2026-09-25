import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';

/// Decorative header illustration for the study-language picker
/// screens — a globe with two floating "speech bubble" language
/// chips (matching the reference design's globe + "A"/"अ" motif).
/// Composed entirely from Flutter shapes/icons rather than a bundled
/// image asset, so it renders crisply at any size and needs no extra
/// binary in the repo.
class LanguageIllustration extends StatelessWidget {
  final double size;
  const LanguageIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryBlue.withValues(alpha: 0.85), AppColors.primaryBlue.withValues(alpha: 0.55)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.public_rounded, color: Colors.white.withValues(alpha: 0.9), size: size * 0.42),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _bubble('A', AppColors.primaryBlue, size),
          ),
          Positioned(
            bottom: 2,
            left: 0,
            child: _bubble('अ', const Color(0xFFED8646), size),
          ),
          Positioned(
            bottom: -4,
            right: size * 0.08,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
              ]),
              child: Icon(Icons.menu_book_rounded, color: const Color(0xFF3D9142), size: size * 0.18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, Color color, double size) {
    return Container(
      width: size * 0.3,
      height: size * 0.3,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(text, style: TextStyle(fontSize: size * 0.14, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
