import 'package:flutter/material.dart';

/// Small circular progress indicator with the percentage centered inside —
/// used on chapter/topic cards to show real completion at a glance.
class ProgressRing extends StatelessWidget {
  final double percent; // 0-100
  final double size;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 44,
    this.color = const Color(0xFF3757C9),
    this.trackColor = const Color(0xFFE7ECF5),
    this.strokeWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clamped / 100,
              strokeWidth: strokeWidth,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${clamped.round()}%',
            style: TextStyle(fontSize: size * 0.24, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
