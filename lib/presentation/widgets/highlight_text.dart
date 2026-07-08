import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.textAlign = TextAlign.right,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final List<InlineSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    
    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }
      
      // Use WidgetSpan for premium highlighting with padding and radius
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD93D),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            text.substring(indexOfMatch, indexOfMatch + query.length),
            style: (style ?? DefaultTextStyle.of(context).style).copyWith(
              color: const Color(0xFF5A4200),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ));
      
      start = indexOfMatch + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: spans,
      ),
    );
  }
}
