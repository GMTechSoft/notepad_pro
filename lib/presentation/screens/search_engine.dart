import 'package:flutter/material.dart';

class SearchEngine {
  final List<String> tokens;
  final List<Color> colors;
  final List<Color> textColors;
  late final Map<String, Color> tokenColorMap;
  late final Map<String, Color> tokenTextColorMap;

  SearchEngine({
    required this.tokens,
    List<Color>? colors,
    List<Color>? textColors,
  })  : colors = colors ?? const [
          Color(0xFFFFD93D),
          Color(0xFFB5EAD7),
          Color(0xFFFFB7B2),
          Color(0xFFC7CEEA),
          Color(0xFFFFA07A),
          Color(0xFF9AD1D4),
          Color(0xFFB39DDB),
          Color(0xFF81C784),
        ],
        textColors = textColors ?? const [
          Color(0xFF5A4200),
          Color(0xFF0D5132),
          Color(0xFF6B1A17),
          Color(0xFF1A237E),
          Color(0xFF8B0000),
          Color(0xFF004D40),
          Color(0xFF4A148C),
          Color(0xFF2E7D32),
        ] {
    tokenColorMap = {};
    tokenTextColorMap = {};
    for (int i = 0; i < tokens.length; i++) {
      final idx = i % this.colors.length;
      tokenColorMap[tokens[i]] = this.colors[idx];
      tokenTextColorMap[tokens[i]] = this.textColors[idx];
    }
  }

  /// Tokenizer that respects quoted phrases.
  static List<String> tokenize(String query) {
    final List<String> result = [];
    final RegExp exp = RegExp(r'"([^"]+)"|(\S+)');
    for (final match in exp.allMatches(query)) {
      final phrase = match.group(1);
      final word = match.group(2);
      if (phrase != null && phrase.isNotEmpty) {
        result.add(phrase.trim());
      } else if (word != null && word.isNotEmpty) {
        result.add(word.trim());
      }
    }
    return result.where((w) => w.isNotEmpty).toList();
  }

  /// Build TextSpans for highlighting.
  List<TextSpan> buildSpans(String source, {int activeMatchIndex = -1}) {
    if (tokens.isEmpty) return [TextSpan(text: source)];
    final List<TextSpan> spans = [];
    String remaining = source;
    int matchIdx = 0;
    while (remaining.isNotEmpty) {
      int? earliest;
      int tokenIdx = -1;
      for (int i = 0; i < tokens.length; i++) {
        final token = tokens[i];
        final idx = remaining.toLowerCase().indexOf(token.toLowerCase());
        if (idx != -1 && (earliest == null || idx < earliest)) {
          earliest = idx;
          tokenIdx = i;
        }
      }
      if (earliest == null) {
        spans.add(TextSpan(text: remaining));
        break;
      }
      if (earliest > 0) {
        spans.add(TextSpan(text: remaining.substring(0, earliest)));
      }
      final token = tokens[tokenIdx];
      final isActive = matchIdx == activeMatchIndex;
      final bg = isActive ? const Color(0xFFFFB300) : tokenColorMap[token]!;
      final fg = isActive ? const Color(0xFF5A4200) : tokenTextColorMap[token]!;
      spans.add(TextSpan(
        text: remaining.substring(earliest, earliest + token.length),
        style: TextStyle(backgroundColor: bg, color: fg),
      ));
      remaining = remaining.substring(earliest + token.length);
      matchIdx++;
    }
    return spans;
  }

  /// Count total matches of all tokens.
  int countTotalMatches(String text) {
    int total = 0;
    final lower = text.toLowerCase();
    for (final t in tokens) {
      total += _countOccurrences(lower, t.toLowerCase());
    }
    return total;
  }

  int _countOccurrences(String source, String sub) {
    if (sub.isEmpty) return 0;
    int count = 0;
    int start = 0;
    while (true) {
      final idx = source.indexOf(sub, start);
      if (idx == -1) break;
      count++;
      start = idx + sub.length;
    }
    return count;
  }
}
