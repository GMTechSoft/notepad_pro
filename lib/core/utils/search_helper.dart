import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/domain/entities/search_result.dart';

class SearchHelper {
  static List<SearchResult> searchFiles(String query, List<VaultFile> allFiles) {
    if (query.trim().isEmpty) return [];

    final String lowerQuery = query.toLowerCase();
    final List<SearchResult> results = [];

    for (final file in allFiles) {
      final String fullText = '${file.title} ${file.description}'.toLowerCase();
      
      // Count total matches in both title and description
      int matchCount = 0;
      int pos = fullText.indexOf(lowerQuery);
      while (pos != -1) {
        matchCount++;
        pos = fullText.indexOf(lowerQuery, pos + lowerQuery.length);
      }

      if (matchCount > 0) {
        final String content = file.description;
        final String lowerContent = content.toLowerCase();
        
        // Preferred Clean UX: Show a single continuous block of description
        // If the match is in the description, we center the window around the first match.
        // Otherwise, we just show the beginning of the description.
        int firstMatchInContent = lowerContent.indexOf(lowerQuery);
        
        String snippet;
        const int maxLength = 150;
        
        if (firstMatchInContent == -1 || firstMatchInContent < maxLength) {
          // Match is in title or near the beginning of description
          snippet = content.length > maxLength 
              ? '${content.substring(0, maxLength)}...' 
              : content;
        } else {
          // Match is deep in the description, start window a bit before it
          int start = firstMatchInContent - 40;
          if (start < 0) start = 0;
          
          int end = start + maxLength;
          if (end > content.length) end = content.length;
          
          snippet = content.substring(start, end);
          if (start > 0) snippet = '...$snippet';
          if (end < content.length) snippet = '$snippet...';
        }

        results.add(SearchResult(
          file: file,
          snippet: snippet,
          matchCount: matchCount,
        ));
      }
    }

    return results;
  }
}
