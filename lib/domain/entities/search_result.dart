import 'package:notepad_pro/domain/entities/vault_file.dart';

class SearchResult {
  final VaultFile file;
  final String snippet;
  final int matchCount;

  SearchResult({
    required this.file,
    required this.snippet,
    required this.matchCount,
  });
}
