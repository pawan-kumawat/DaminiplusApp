import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders plain text with math mixed in, most reliable path first:
///  1. Explicit \(...\), \[...\], or $...$ delimiters — always tried
///     first, for any formula of any complexity.
///  2. Token-based auto-detection for un-delimited math dropped straight
///     into a sentence — e.g. an admin typing
///     "What is \frac{2}{3} of 1\frac{2}{5} of 75\% of 540?" or a Hindi
///     question with a bare LaTeX clause in the middle. Text is split on
///     whitespace *outside* any {...} group (so a fraction's own spaces,
///     e.g. \frac{x^{n+1}}{n + 1}, never get chopped), consecutive
///     tokens containing \, ^, _, { or } are merged into one run and
///     rendered, and everything else — Hindi words, "What is", "of",
///     "540?" — stays untouched. A run that fails to parse falls back
///     to its own original text only, so one bad fragment can't blank
///     out the rest of the sentence.
///  3. Unicode math pasted straight out of somewhere like ChatGPT's
///     rendered output ("∫xⁿ dx = xⁿ⁺¹/(n + 1) + C") gets its
///     superscripts/symbols normalized to LaTeX first, so it flows into
///     the same token pipeline as path 2.
///  4. A bare numeric fraction with no other math signal at all, e.g.
///     "1/2", still becomes a stacked fraction — narrow enough that
///     ordinary slashes ("and/or", "he/she") are never touched.
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const MathText(this.text, {super.key, this.style, this.textAlign = TextAlign.start});

  static final RegExp _delimiterPattern = RegExp(
    r'\\\((.*?)\\\)|\\\[(.*?)\\\]|\$(.*?)\$',
    dotAll: true,
  );

  // Unicode superscript/subscript runs → ^{...} / _{...}.
  static final RegExp _supRun = RegExp('[⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿⁱ]+');
  static final RegExp _subRun = RegExp('[₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎]+');
  static const Map<String, String> _supMap = {
    '⁰': '0', '¹': '1', '²': '2', '³': '3', '⁴': '4', '⁵': '5', '⁶': '6', '⁷': '7', '⁸': '8', '⁹': '9',
    '⁺': '+', '⁻': '-', '⁼': '=', '⁽': '(', '⁾': ')', 'ⁿ': 'n', 'ⁱ': 'i',
  };
  static const Map<String, String> _subMap = {
    '₀': '0', '₁': '1', '₂': '2', '₃': '3', '₄': '4', '₅': '5', '₆': '6', '₇': '7', '₈': '8', '₉': '9',
    '₊': '+', '₋': '-', '₌': '=', '₍': '(', '₎': ')',
  };
  // Common math symbols → LaTeX commands.
  static const Map<String, String> _symbolMap = {
    '∫': r'\int ', '√': r'\sqrt', '±': r'\pm ', '×': r'\times ', '÷': r'\div ', '→': r'\to ',
    '≤': r'\le ', '≥': r'\ge ', '≠': r'\neq ', '≈': r'\approx ', 'π': r'\pi ', 'θ': r'\theta ',
    'α': r'\alpha ', 'β': r'\beta ', 'Δ': r'\Delta ', '∞': r'\infty ',
  };
  // a/b or a/(expr) → \frac{a}{b} — only applied when the segment already
  // has a strong math signal elsewhere, so a broad alnum match here can't
  // catch ordinary prose slashes.
  static final RegExp _fractionPattern = RegExp(r'([A-Za-z0-9^_{}\\+\-]+)/(\([^()]*\)|[A-Za-z0-9^_{}\\+\-]+)');
  // Narrow standalone fallback for un-flagged prose — digits only, so
  // "and/or" or "he/she" are never mistaken for a fraction.
  static final RegExp _digitFractionPattern = RegExp(r'\b(\d+)\s*/\s*(\d+)\b');
  static final RegExp _strongMathSignal = RegExp('[\\\\∫√±×÷→≤≥≠≈πθαβΔ∞⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻ⁿⁱ₀₁₂₃₄₅₆₇₈₉]');

  // flutter_math_fork's bundled math fonts only cover Latin + math
  // symbols — \text{...} with Hindi/other non-Latin content inside a
  // formula (very common here, e.g. "10\text{ मीटर}") silently renders
  // with missing glyphs, even though it's valid LaTeX and shows fine in
  // the browser-based admin preview (which just defers to the page's
  // own Unicode-capable font for text mode). Pulling that content out
  // and rendering it as an ordinary Text span sidesteps the gap — plain
  // Flutter text widgets get full OS font fallback.
  static final RegExp _textCommandPattern = RegExp(r'\\text\{([^{}]*)\}');
  static final RegExp _nonAsciiPattern = RegExp(r'[^\x00-\x7F]');

  static List<(String, bool)> _splitNonLatinText(String latex) {
    final matches = _textCommandPattern.allMatches(latex).toList();
    final parts = <(String, bool)>[];
    var cursor = 0;
    for (final m in matches) {
      final inner = m.group(1) ?? '';
      if (!_nonAsciiPattern.hasMatch(inner)) continue; // ASCII \text{} renders fine — leave it inline
      if (m.start > cursor) parts.add((latex.substring(cursor, m.start), true));
      parts.add((inner, false));
      cursor = m.end;
    }
    if (parts.isEmpty) return [(latex, true)];
    if (cursor < latex.length) parts.add((latex.substring(cursor), true));
    return parts;
  }

  static String _normalizeSymbols(String s) {
    s = s.replaceAllMapped(_supRun, (m) => '^{${m[0]!.split('').map((c) => _supMap[c] ?? c).join()}}');
    s = s.replaceAllMapped(_subRun, (m) => '_{${m[0]!.split('').map((c) => _subMap[c] ?? c).join()}}');
    _symbolMap.forEach((sym, latex) => s = s.replaceAll(sym, latex));
    return s;
  }

  static String _normalizeFractions(String s) {
    return s.replaceAllMapped(_fractionPattern, (m) {
      final a = m.group(1)!;
      var b = m.group(2)!;
      if (b.startsWith('(') && b.endsWith(')')) b = b.substring(1, b.length - 1);
      return '\\frac{$a}{$b}';
    });
  }

  // Splits on whitespace that sits outside any {...} group, so a
  // fraction's own internal spaces (\frac{x^{n+1}}{n + 1}) stay in one
  // token instead of getting chopped mid-expression.
  static List<String> _tokenize(String s) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var depth = 0;
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '{') depth++;
      if (ch == '}' && depth > 0) depth--;
      if (ch == ' ' && depth == 0) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(ch);
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }

  static bool _isMathyToken(String t) =>
      t.contains('\\') || t.contains('^') || t.contains('_') || t.contains('{') || t.contains('}');

  static List<InlineSpan> _renderDigitFractions(String plain, TextStyle style) {
    final matches = _digitFractionPattern.allMatches(plain).toList();
    if (matches.isEmpty) return [TextSpan(text: plain, style: style)];
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) spans.add(TextSpan(text: plain.substring(cursor, m.start), style: style));
      final raw = m.group(0)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          '\\frac{${m.group(1)}}{${m.group(2)}}',
          mathStyle: MathStyle.text,
          textStyle: style,
          onErrorFallback: (_) => Text(raw, style: style),
        ),
      ));
      cursor = m.end;
    }
    if (cursor < plain.length) spans.add(TextSpan(text: plain.substring(cursor), style: style));
    return spans;
  }

  static List<InlineSpan> _renderPlainSegment(String segment, TextStyle style) {
    if (segment.isEmpty) return const [];

    var normalized = _normalizeSymbols(segment);
    if (_strongMathSignal.hasMatch(segment)) {
      normalized = _normalizeFractions(normalized);
    }

    final tokens = _tokenize(normalized);
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    bool? bufferIsMathy;

    void flush() {
      if (buffer.isEmpty) return;
      final content = buffer.toString();
      if (bufferIsMathy == true) {
        for (final part in _splitNonLatinText(content)) {
          final (partText, isMath) = part;
          if (isMath) {
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Math.tex(
                partText,
                mathStyle: MathStyle.text,
                textStyle: style,
                onErrorFallback: (_) => Text(partText, style: style),
              ),
            ));
          } else {
            spans.add(TextSpan(text: partText, style: style));
          }
        }
      } else {
        spans.addAll(_renderDigitFractions(content, style));
      }
      buffer.clear();
    }

    for (final token in tokens) {
      final mathy = _isMathyToken(token);
      if (bufferIsMathy != null && mathy != bufferIsMathy) flush();
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(token);
      bufferIsMathy = mathy;
    }
    flush();
    return spans;
  }

  // Shared with call sites that need the raw spans (e.g. rough-work's
  // "See More" card, which drives its own TextPainter for overflow
  // detection and can't feed WidgetSpans through that path).
  static List<InlineSpan> buildSpans(String text, TextStyle style) {
    final matches = _delimiterPattern.allMatches(text).toList();
    if (matches.isEmpty) return _renderPlainSegment(text, style);

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.addAll(_renderPlainSegment(text.substring(cursor, m.start), style));
      }
      final formula = m.group(1) ?? m.group(2) ?? m.group(3) ?? '';
      for (final part in _splitNonLatinText(formula)) {
        final (partText, isMath) = part;
        if (isMath) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Math.tex(
              partText,
              mathStyle: MathStyle.text,
              textStyle: style,
              onErrorFallback: (_) => Text(partText, style: style),
            ),
          ));
        } else {
          spans.add(TextSpan(text: partText, style: style));
        }
      }
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.addAll(_renderPlainSegment(text.substring(cursor), style));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(TextSpan(children: buildSpans(text, effectiveStyle)), textAlign: textAlign);
  }
}
