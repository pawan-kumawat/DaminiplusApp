import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../widgets/math_text.dart';

/// Dedicated full-screen scratchpad for a student's rough work — the
/// question stays visible at the top (fixed, not scrollable) and the
/// canvas fills the rest of the screen exactly, so drawing never
/// competes with a page scroll gesture. Deliberately has no save/
/// persistence anywhere — strokes live only in this screen's state and
/// are gone the moment it's popped.
class RoughWorkSolveScreen extends StatefulWidget {
  final String questionText;
  const RoughWorkSolveScreen({super.key, required this.questionText});

  @override
  State<RoughWorkSolveScreen> createState() => _RoughWorkSolveScreenState();
}

enum _RoughTool { pen, eraser }

class _RoughStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
  _RoughStroke(this.points, this.color, this.width, this.isEraser);
}

class _RoughWorkSolveScreenState extends State<RoughWorkSolveScreen> {
  final List<_RoughStroke> _strokes = [];
  final List<_RoughStroke> _redoStack = [];
  _RoughStroke? _current;
  Color _color = const Color(0xFF1E293B);
  double _strokeWidth = 3.5;
  _RoughTool _tool = _RoughTool.pen;
  bool _questionExpanded = false;

  static const _colors = [
    Color(0xFF1E293B),
    Color(0xFFEF4444),
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
  ];

  void _start(Offset p) {
    setState(() {
      _current = _RoughStroke([p], _color, _tool == _RoughTool.eraser ? 22 : _strokeWidth, _tool == _RoughTool.eraser);
    });
  }

  void _move(Offset p) {
    if (_current == null) return;
    setState(() => _current!.points.add(p));
  }

  void _end() {
    if (_current == null) return;
    setState(() {
      _strokes.add(_current!);
      _current = null;
      _redoStack.clear();
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _redoStack.add(_strokes.removeLast()));
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() => _strokes.add(_redoStack.removeLast()));
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _redoStack.clear();
      _current = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _strokes.isEmpty && _current == null;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: const Text('Solve', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.undo_rounded, color: _strokes.isEmpty ? Colors.grey.shade300 : Colors.black54),
            tooltip: 'Undo',
            onPressed: _strokes.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: Icon(Icons.redo_rounded, color: _redoStack.isEmpty ? Colors.grey.shade300 : Colors.black54),
            tooltip: 'Redo',
            onPressed: _redoStack.isEmpty ? null : _redo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.black54),
            tooltip: 'Clear all',
            onPressed: isEmpty ? null : _clear,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Question card ──────────────────────
            _buildQuestionCard(),

            // ── Canvas ──────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (d) => _start(d.localPosition),
                        onPanUpdate: (d) => _move(d.localPosition),
                        onPanEnd: (_) => _end(),
                        child: CustomPaint(
                          painter: _RoughPainter(strokes: _strokes, current: _current),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                    if (isEmpty)
                      IgnorePointer(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.draw_outlined, size: 38, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text('Start solving here', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 13.5)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Toolbar ─────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  _toolButton(icon: Icons.edit_rounded, selected: _tool == _RoughTool.pen, onTap: () => setState(() => _tool = _RoughTool.pen)),
                  _toolButton(icon: Icons.auto_fix_normal_rounded, selected: _tool == _RoughTool.eraser, onTap: () => setState(() => _tool = _RoughTool.eraser)),
                  Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 6), color: Colors.grey.shade200),
                  ..._colors.map((c) => GestureDetector(
                        onTap: () => setState(() {
                          _color = c;
                          _tool = _RoughTool.pen;
                        }),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: (_tool == _RoughTool.pen && _color == c) ? Colors.black87 : Colors.transparent, width: 2),
                          ),
                        ),
                      )),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 2), color: Colors.grey.shade200),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: _strokeWidth,
                        min: 1.5,
                        max: 8,
                        activeColor: AppColors.primaryBlue,
                        inactiveColor: Colors.grey.shade200,
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    const collapsedLines = 4;
    const bodyStyle = TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy, fontSize: 13.5, height: 1.4);
    // Plain-text span purely to drive TextPainter's overflow check below —
    // WidgetSpans (used by the math-aware render below) can't be measured
    // by a standalone TextPainter without pre-set placeholder dimensions.
    final measureSpan = TextSpan(
      children: [
        const TextSpan(text: 'Q: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 13.5)),
        TextSpan(text: widget.questionText, style: bodyStyle),
      ],
    );
    final displaySpan = TextSpan(
      children: [
        const TextSpan(text: 'Q: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 13.5)),
        ...MathText.buildSpans(widget.questionText, bodyStyle),
      ],
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: AppColors.primaryBlue.withOpacity(0.7), width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tp = TextPainter(text: measureSpan, maxLines: collapsedLines, textDirection: TextDirection.ltr)
            ..layout(maxWidth: constraints.maxWidth);
          final isLong = tp.didExceedMaxLines;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_questionExpanded && isLong)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(child: RichText(text: displaySpan)),
                )
              else
                RichText(maxLines: collapsedLines, overflow: TextOverflow.ellipsis, text: displaySpan),
              if (isLong) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _questionExpanded = !_questionExpanded),
                  child: Text(
                    _questionExpanded ? 'See Less' : 'See More',
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _toolButton({required IconData icon, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: selected ? AppColors.primaryBlue : Colors.grey.shade500),
      ),
    );
  }
}

class _RoughPainter extends CustomPainter {
  final List<_RoughStroke> strokes;
  final _RoughStroke? current;
  _RoughPainter({required this.strokes, this.current});

  void _drawStroke(Canvas canvas, _RoughStroke s) {
    final color = s.isEraser ? Colors.white : s.color;
    if (s.points.length == 1) {
      canvas.drawCircle(s.points.first, s.width / 2, Paint()..color = color);
      return;
    }
    if (s.points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = s.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
    for (final p in s.points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    for (final s in strokes) {
      _drawStroke(canvas, s);
    }
    if (current != null) _drawStroke(canvas, current!);
  }

  @override
  bool shouldRepaint(covariant _RoughPainter oldDelegate) => true;
}
