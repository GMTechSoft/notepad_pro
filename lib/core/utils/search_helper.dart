import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/domain/entities/search_result.dart';
import 'package:notepad_pro/core/utils/search_mode.dart';

class SearchHelper {
  static List<SearchResult> searchFiles(String query, List<VaultFile> allFiles, SearchMode mode) {
    if (query.trim().isEmpty) return [];
    final words = _getSearchWords(query);
    final lowerQuery = query.toLowerCase();
    final List<SearchResult> results = [];

    for (final file in allFiles) {
      final fullText = '${file.title} ${file.description}'.toLowerCase();
      bool matches = false;
      int totalMatches = 0;
      final Map<String, int> wordCounts = {};

      if (mode == SearchMode.exact) {
        // Exact phrase match
        int pos = fullText.indexOf(lowerQuery);
        while (pos != -1) {
          totalMatches++;
          pos = fullText.indexOf(lowerQuery, pos + lowerQuery.length);
        }
        if (totalMatches > 0) {
          matches = true;
          wordCounts[query] = totalMatches;
        }
      } else {
        // anyWord or allWords
        for (final w in words) {
          final lowerW = w.toLowerCase();
          int count = 0;
          int pos = fullText.indexOf(lowerW);
          while (pos != -1) {
            count++;
            pos = fullText.indexOf(lowerW, pos + lowerW.length);
          }
          if (count > 0) {
            wordCounts[w] = count;
            totalMatches += count;
          }
        }
        if (mode == SearchMode.anyWord) {
          matches = wordCounts.isNotEmpty;
        } else if (mode == SearchMode.allWords) {
          matches = wordCounts.length == words.length;
        }
      }

      if (matches) {
        final previewLines = _extractPreviewLines(file.description, query, words, mode);
        results.add(SearchResult(
          file: file,
          wordCounts: wordCounts,
          totalMatches: totalMatches,
          previewLines: previewLines,
        ));
      }
    }
    return results;
  }

  static List<String> _extractPreviewLines(String content, String query, List<String> words, SearchMode mode) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).map((l) => l.trim()).toList();
    List<String> matches = [];
    if (mode == SearchMode.exact) {
      matches = lines.where((line) => line.toLowerCase().contains(query.toLowerCase())).take(3).toList();
    } else {
      matches = lines.where((line) => words.any((w) => line.toLowerCase().contains(w.toLowerCase()))).take(3).toList();
    }
    if (matches.isNotEmpty) return matches;
    // fallback to first lines
    return lines.take(2).toList();
  }

  static List<String> _getSearchWords(String query) {
    return query.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }
}
