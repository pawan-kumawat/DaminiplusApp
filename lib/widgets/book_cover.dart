// ─────────────────────────────────────────────────────────────
// book_cover.dart
// Shared "book cover" tile used by the Books/Notes/Previous-Papers
// list and detail screens. If the subject has an uploaded image we
// show that; otherwise we render a deterministic colour-gradient
// cover with the subject name printed on it, so every card still
// looks distinct instead of a single generic placeholder icon.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

const List<List<Color>> _coverGradients = [
  [Color(0xFF1E3A8A), Color(0xFF3B5FCB)],
  [Color(0xFF14532D), Color(0xFF22A06B)],
  [Color(0xFF7C1D46), Color(0xFFB0295B)],
  [Color(0xFF7C4A03), Color(0xFFC2830B)],
  [Color(0xFF4C1D95), Color(0xFF7C3AED)],
  [Color(0xFF9A3412), Color(0xFFEA580C)],
  [Color(0xFF0F766E), Color(0xFF14B8A6)],
  [Color(0xFF1E293B), Color(0xFF475569)],
];

List<Color> coverGradientFor(String seed) {
  if (seed.isEmpty) return _coverGradients[0];
  return _coverGradients[seed.hashCode.abs() % _coverGradients.length];
}

class BookCover extends StatelessWidget {
  final String title;
  final String? subtitle; // e.g. class name
  final String? badge; // e.g. board name
  final String imageUrl;
  final double borderRadius;

  const BookCover({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.imageUrl = '',
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _GeneratedCover(
            title: title,
            subtitle: subtitle,
            badge: badge,
            borderRadius: borderRadius,
          ),
        ),
      );
    }
    return _GeneratedCover(
      title: title,
      subtitle: subtitle,
      badge: badge,
      borderRadius: borderRadius,
    );
  }
}

class _GeneratedCover extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final double borderRadius;

  const _GeneratedCover({
    required this.title,
    this.subtitle,
    this.badge,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = coverGradientFor(title);
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null && badge!.isNotEmpty)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colors[0],
                  ),
                ),
              ),
            ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.15,
              ),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
