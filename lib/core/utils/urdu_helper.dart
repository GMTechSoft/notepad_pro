bool isUrduText(String text) {
  if (text.trim().isEmpty) return false;
  int urduCount = 0;
  int totalCount = 0;
  for (final rune in text.runes) {
    if (rune <= 32) continue; // ignore whitespace
    if (rune >= 48 && rune <= 57) continue; // ignore digits
    totalCount++;
    if ((rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF)) {
      urduCount++;
    }
  }
  if (totalCount == 0) return false;
  return (urduCount / totalCount) >= 0.3;
}
