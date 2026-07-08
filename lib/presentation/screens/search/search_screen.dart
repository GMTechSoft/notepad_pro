import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/core/utils/search_helper.dart';
import 'package:notepad_pro/domain/entities/search_result.dart';
import 'package:notepad_pro/services/hive_service.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HiveService _hiveService = sl<HiveService>();

  String _query = '';
  String _activeFilter = 'all';
  List<SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController.text = widget.initialQuery;
    if (_query.isNotEmpty) {
      _performSearch(_query);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterPills(),
          _buildSummaryBar(),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isRTL = _isUrdu(_query);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9F8),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD8D0F0),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2D2540),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: isRTL ? 'تلاش کریں...' : 'Search notes...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB0A0CC),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    suffixIcon: const Icon(
                      Icons.search,
                      size: 16,
                      color: Color(0xFFC4B8E0),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _query = val;
                      if (_activeFilter == 'english' && _isUrdu(val)) {
                        _activeFilter = 'all';
                      } else if (_activeFilter == 'urdu' && !_isUrdu(val)) {
                        _activeFilter = 'all';
                      }
                    });
                    _performSearch(val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _results = [];
                  _isSearching = false;
                });
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9F8),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    final isRTL = _isUrdu(_query);
    final filters = isRTL
        ? [
            {'key': 'all', 'label': 'سب'},
            {'key': 'title', 'label': 'عنوان'},
            {'key': 'content', 'label': 'مواد'},
            {'key': 'urdu', 'label': 'اردو'},
          ]
        : [
            {'key': 'all', 'label': 'All'},
            {'key': 'title', 'label': 'Title only'},
            {'key': 'content', 'label': 'Content'},
            {'key': 'english', 'label': 'English'},
          ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: isRTL,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isActive = _activeFilter == f['key'];
          return GestureDetector(
            onTap: () {
              setState(() => _activeFilter = f['key']!);
              _performSearch(_query);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFEDE9F8) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF6C5CE7)
                      : const Color(0xFFD8D0F0),
                  width: 0.5,
                ),
              ),
              child: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFF6C5CE7)
                      : const Color(0xFF9B8DB8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar() {
    if (_query.isEmpty) return const SizedBox.shrink();

    final totalFiles = _results.length;
    final totalMatches = _results.fold<int>(
      0,
      (sum, r) => sum + r.matchCount,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 14,
            color: Color(0xFF6C5CE7),
          ),
          const SizedBox(width: 5),
          Text(
            '$totalFiles file mein mila',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6C5CE7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9F8),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '$totalMatches matches',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_query.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'Kuch likhein',
        subtitle: 'Notes aur folders mein search karein',
      );
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF6C5CE7)),
        ),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_outlined,
        title: 'Koi result nahi mila',
        subtitle: '"$_query" ke liye kuch nahi mila',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (context, i) => _buildResultCard(_results[i]),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: const Color(0xFF6C5CE7)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2540),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9B8DB8)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(SearchResult result) {
    final file = result.file;
    final content = file.description;
    final isRTL = _isUrdu(content);
    final textDir = isRTL ? TextDirection.rtl : TextDirection.ltr;
    final textAlign = isRTL ? TextAlign.right : TextAlign.left;
    final folderName = _getFolderName(file.folderId) ?? 'Root';
    final dateLabel = _getRelativeDate(file.updatedAt);
    final previewLines = _extractPreviewLines(content, _query, result.snippet);

    return GestureDetector(
      onTap: () => context.push('/read-note', extra: file),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 6),
              child: Column(
                crossAxisAlignment:
                    isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildHighlightedText(
                    text: file.title,
                    query: _query,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D2540),
                    ),
                    textAlign: textAlign,
                    textDirection: textDir,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$folderName · $dateLabel',
                    textDirection: textDir,
                    textAlign: textAlign,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9B8DB8),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: Color(0xFFF5F0FF),
              thickness: 0.5,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 6, 11, 6),
              child: Column(
                crossAxisAlignment:
                    isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: previewLines
                    .take(3)
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _buildHighlightedText(
                          text: line,
                          query: _query,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6D6380),
                            height: 1.6,
                          ),
                          textAlign: textAlign,
                          textDirection: textDir,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9F8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${result.matchCount} matches',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6C5CE7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5EE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isRTL ? 'Urdu' : 'English',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0F6E56),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9F8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Open ->',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6C5CE7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText({
    required String text,
    required String query,
    required TextStyle style,
    TextAlign textAlign = TextAlign.left,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: style.copyWith(
            backgroundColor: const Color(0xFFFFD93D),
            color: const Color(0xFF5A4200),
            fontWeight: FontWeight.w500,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign,
      textDirection: textDirection,
    );
  }

  bool _isUrdu(String text) {
    if (text.isEmpty) return false;
    final urduRegex = RegExp(r'[\u0600-\u06FF]');
    return urduRegex.hasMatch(text);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final raw = await Future<List<SearchResult>>(() {
      final allFiles = _hiveService.fileBox.values
          .map((fileModel) => fileModel.toEntity())
          .toList();
      return SearchHelper.searchFiles(query, allFiles);
    });

    if (!mounted || query != _query) return;

    final lowerQuery = query.toLowerCase();
    final filtered = raw.where((r) {
      switch (_activeFilter) {
        case 'title':
          return r.file.title.toLowerCase().contains(lowerQuery);
        case 'content':
          return r.file.description.toLowerCase().contains(lowerQuery);
        case 'english':
          return !_isUrdu('${r.file.title} ${r.file.description}');
        case 'urdu':
          return _isUrdu('${r.file.title} ${r.file.description}');
        default:
          return true;
      }
    }).toList();

    setState(() {
      _results = filtered;
      _isSearching = false;
    });
  }

  List<String> _extractPreviewLines(
    String content,
    String query,
    String fallbackSnippet,
  ) {
    final lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();
    final lowerQuery = query.toLowerCase();
    final matches = lines
        .where((line) => line.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();

    if (matches.isNotEmpty) return matches;
    if (fallbackSnippet.trim().isNotEmpty) return [fallbackSnippet.trim()];
    return lines.take(2).toList();
  }

  String? _getFolderName(String? folderId) {
    if (folderId == null) return null;
    final folder = _hiveService.folderBox.get(folderId);
    return folder?.name;
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thatDay = DateTime(date.year, date.month, date.day);

    if (today == thatDay) return 'Today';
    if (yesterday == thatDay) return 'Yesterday';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}

class VaultSearchDelegate extends SearchDelegate<void> {
  @override
  String get searchFieldLabel => 'Search notes...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          if (query.isEmpty) {
            close(context, null);
          } else {
            query = '';
          }
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return SearchScreen(initialQuery: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return SearchScreen(initialQuery: query);
  }
}
