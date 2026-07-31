import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/core/utils/search_helper.dart';
import 'package:notepad_pro/core/utils/search_mode.dart';
import 'package:notepad_pro/domain/entities/search_result.dart';
import 'package:notepad_pro/presentation/widgets/highlight_text.dart';

import '../../../../services/hive_service.dart';

/// SearchDelegate used in the empty vault view.
class VaultSearchDelegate extends SearchDelegate<String> {
  final HiveService _hiveService = sl<HiveService>();

  VaultSearchDelegate() : super();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<SearchResult>>(
      future: _performSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(child: Text('No results for "$query"'));
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              title: HighlightText(
                text: result.file.title,
                query: query,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(result.file.description),
              onTap: () {
                close(context, query);
                context.push('/read-note', extra: {
                  'file': result.file,
                  'highlightQuery': query,
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);

  Future<List<SearchResult>> _performSearch(String q) async {
    if (q.trim().isEmpty) return [];
    final allFiles = _hiveService.fileBox.values.map((f) => f.toEntity()).toList();
    return SearchHelper.searchFiles(q, allFiles, SearchMode.anyWord);
  }
}
