import 'package:notepad_pro/domain/entities/vault_file.dart';

class SearchResult {
  final VaultFile file;
  final Map<String, int> wordCounts;
  final int totalMatches;
  final List<String> previewLines;

  const SearchResult({
    required this.file,
    required this.wordCounts,
    required this.totalMatches,
    required this.previewLines,
  });
}
