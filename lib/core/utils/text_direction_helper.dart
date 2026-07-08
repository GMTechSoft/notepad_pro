import 'package:flutter/material.dart';

class TextDirectionHelper {
  /// Detects if a string starts with an RTL character (like Urdu/Arabic)
  static TextDirection getDirection(String text) {
    if (text.trim().isEmpty) return TextDirection.ltr;

    // Check the first few non-whitespace characters
    final trimmed = text.trim();
    for (int i = 0; i < trimmed.length && i < 10; i++) {
      int codeUnit = trimmed.codeUnitAt(i);
      
      // Arabic/Urdu/Persian Unicode range: 0x0600 to 0x06FF
      // Arabic Supplement: 0x0750 to 0x077F
      // Arabic Extended-A: 0x08A0 to 0x08FF
      if ((codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
          (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
          (codeUnit >= 0x08A0 && codeUnit <= 0x08FF)) {
        return TextDirection.rtl;
      }
      
      // If we find an alphanumeric character that is definitely LTR, we can stop and return LTR
      if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) || // A-Z
          (codeUnit >= 0x0061 && codeUnit <= 0x007A)) { // a-z
        return TextDirection.ltr;
      }
    }

    return TextDirection.ltr;
  }
}
