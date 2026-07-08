import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// Returns the color value as a 32-bit integer in ARGB format.
  /// This is a wrapper around the now-deprecated [value] property
  /// to provide a consistent transition path.
  int toARGB() {
    // ignore: deprecated_member_use
    return value;
  }
}
