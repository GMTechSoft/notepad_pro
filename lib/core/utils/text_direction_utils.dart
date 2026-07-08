import 'package:flutter/material.dart';

class TextDirectionUtils {
  /// Detects if a string starts with an RTL character (like Urdu/Arabic)
  /// This is "smart" because it prioritizes the beginning of the text.
  static TextDirection getDirection(String text) {
    if (text.trim().isEmpty) return TextDirection.ltr;

    // Check the first few non-whitespace characters
    final trimmed = text.trim();
    for (int i = 0; i < trimmed.length && i < 15; i++) {
      int codeUnit = trimmed.codeUnitAt(i);
      
      // Arabic/Urdu range: 0x0600 to 0x06FF
      if ((codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
          (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
          (codeUnit >= 0x08A0 && codeUnit <= 0x08FF) ||
          (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
          (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF)) {
        return TextDirection.rtl;
      }
      
      // Definitely LTR (English)
      if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) || // A-Z
          (codeUnit >= 0x0061 && codeUnit <= 0x007A)) { // a-z
        return TextDirection.ltr;
      }
    }

    return TextDirection.ltr;
  }

  static TextAlign getTextAlign(String text) {
    return getDirection(text) == TextDirection.rtl ? TextAlign.right : TextAlign.left;
  }
}
