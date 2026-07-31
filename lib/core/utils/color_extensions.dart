import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// Returns the color value as a 32-bit integer in ARGB format.
  int toARGB() {
    // ignore: deprecated_member_use
    return value;
  }
}
