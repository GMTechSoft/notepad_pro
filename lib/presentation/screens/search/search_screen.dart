import 'package:flutter/material.dart';
import 'package:notepad_pro/presentation/screens/search_engine.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:notepad_pro/core/di/service_locator.dart';
import 'package:notepad_pro/core/utils/search_helper.dart';
import 'package:notepad_pro/domain/entities/search_result.dart';
import 'package:notepad_pro/core/utils/search_mode.dart';

import '../../../domain/entities/vault_file.dart';
import '../../../services/hive_service.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  final String? folderId; // Scoped search support added

  const SearchScreen({super.key, this.initialQuery = '', this.folderId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Map<String, Color> _wordColorMap = {};
  List<String> _searchTokens = [];

  final TextEditingController _searchController = TextEditingController();
  final HiveService _hiveService = sl<HiveService>();

  String _query = '';
  List<SearchResult> _results = [];
  bool _isSearching = false;
  String _activeFilter = 'all';
  final SearchMode _searchMode = SearchMode.anyWord;

  final List<Color> _multiHighlighterPalette = [
    const Color(0xFFFFD54F), // Amber/Yellow
    const Color(0xFF81C784), // Soft Green
    const Color(0xFF4FC3F7), // Light Blue
    const Color(0xFFFF8A65), // Coral/Orange
    const Color(0xFFBA68C8), // Purple
    const Color(0xFF4DB6AC), // Teal
    const Color(0xFFE57373), // Red/Pink
    const Color(0xFFAED581), // Lime Green
  ];

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
      backgroundColor: context.scaffoldBg,
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
                  color: context.highlightBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.arrow_back, size: 16, color: context.primaryColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.border, width: 0.5),
                ),
                child: TextField(
                  controller: _searchController,
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  autofocus: true,
                  style: TextStyle(fontSize: 13, color: context.primaryText, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: isRTL ? 'تلاش کریں...' : 'Search notes...',
                    hintStyle: TextStyle(fontSize: 13, color: context.subText),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    suffixIcon: Icon(Icons.search, size: 16, color: context.border),
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
                    _performSearch(_query);
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
                  _wordColorMap = {}; // Fixed name to avoid target compiler failure
                  _searchTokens = [];
                });
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: context.highlightBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(Icons.close, size: 16, color: context.primaryColor),
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
                color: isActive ? context.highlightBg : context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? context.primaryColor : context.border, width: 0.5),
              ),
              child: Text(f['label']!, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w500 : FontWeight.w400, color: isActive ? context.primaryColor : context.subText)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar() {
    if (_query.isEmpty) return const SizedBox.shrink();
    final totalFiles = _results.length;
    final totalMatches = _results.fold<int>(0, (sum, r) => sum + r.totalMatches);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.border, width: 0.5)),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 14, color: context.primaryColor),
          const SizedBox(width: 5),
          Text('Found in $totalFiles file${totalFiles == 1 ? "" : "s"}', style: TextStyle(fontSize: 11, color: context.primaryColor, fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: context.highlightBg, borderRadius: BorderRadius.circular(5)), child: Text('$totalMatches matches', style: TextStyle(fontSize: 11, color: context.primaryColor, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_query.isEmpty) return _buildEmptyState(icon: Icons.search, title: 'Type something to search', subtitle: 'Search in notes and folders');
    if (_isSearching) return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(context.primaryColor)));
    if (_results.isEmpty) return _buildEmptyState(icon: Icons.search_off_outlined, title: 'No results found', subtitle: 'No matches found for "$_query"');
    return ListView.separated(padding: const EdgeInsets.fromLTRB(12, 0, 12, 20), itemCount: _results.length, separatorBuilder: (_, __) => const SizedBox(height: 7), itemBuilder: (context, i) => _buildResultCard(_results[i]));
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: context.highlightBg, borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 26, color: context.primaryColor)),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.primaryText)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.subText)),
      ]),
    );
  }

  Widget _buildResultCard(SearchResult result) {
    final file = result.file;
    final isRTL = _isUrdu(file.description);
    final textDir = isRTL ? TextDirection.rtl : TextDirection.ltr;
    final textAlign = isRTL ? TextAlign.right : TextAlign.left;
    final folderName = _getFolderName(file.folderId) ?? 'Root';
    final dateLabel = _getRelativeDate(file.updatedAt);
    final engine = SearchEngine(tokens: SearchEngine.tokenize(_query));
 
    String combinedContent = "${file.title} ${file.description}".toLowerCase();
    Map<String, int> dynamicWordCounts = {};
    for (String token in _searchTokens) {
      final escapedToken = RegExp.escape(token.toLowerCase());
      dynamicWordCounts[token] = RegExp(escapedToken).allMatches(combinedContent).length;
    }
 
    return GestureDetector(
      onTap: () => context.push('/read-note', extra: {
        'file': file,
        'searchEngine': engine,
        'searchMode': _searchMode.name,
        'highlightQuery': _query,
        'highlightWords': _searchTokens,
        'highlightColors': _wordColorMap,
      }),
      child: Container(
        decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.border, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.fromLTRB(11, 9, 11, 6), child: Column(crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            _buildMultiHighlight(text: file.title, baseStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primaryText), textDirection: textDir, textAlign: textAlign),
            const SizedBox(height: 2),
            Text('$folderName · $dateLabel', textDirection: textDir, textAlign: textAlign, style: TextStyle(fontSize: 10, color: context.subText)),
          ])),
          Divider(height: 1, color: context.border, thickness: 0.5),
          Padding(padding: const EdgeInsets.fromLTRB(11, 6, 11, 6), child: Column(crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: result.previewLines.take(3).map((line) => Padding(padding: const EdgeInsets.only(bottom: 2), child: _buildMultiHighlight(text: line, baseStyle: TextStyle(fontSize: 11, color: context.subText, height: 1.6), textDirection: textDir, textAlign: textAlign))).toList())),
          Padding(padding: const EdgeInsets.fromLTRB(11, 0, 11, 8), child: Row(children: [
            Expanded(
              child: Wrap(
                spacing: 4, 
                runSpacing: 4,
                children: dynamicWordCounts.entries.where((e) => e.value > 0).map((e) {
                  final color = _wordColorMap[e.key] ?? Colors.grey;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5)), 
                    child: Text('${e.key} ×${e.value}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600))
                  );
                }).toList()
              ),
            ),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: context.highlightBg, borderRadius: BorderRadius.circular(5)), child: Text('Open ->', style: TextStyle(fontSize: 10, color: context.primaryColor, fontWeight: FontWeight.w500))),
          ])),
        ]),
      ),
    );
  }

  Widget _buildMultiHighlight({required String text, required TextStyle baseStyle, required TextDirection textDirection, required TextAlign textAlign}) {
    if (_searchTokens.isEmpty) return Text(text, style: baseStyle, textDirection: textDirection, textAlign: textAlign);
    final spans = <TextSpan>[];
    String remaining = text;
    
    while (remaining.isNotEmpty) {
      int? earliest; 
      String? matchedToken;
      
      for (final token in _searchTokens) {
        final idx = remaining.toLowerCase().indexOf(token.toLowerCase());
        if (idx != -1 && (earliest == null || idx < earliest)) { 
          earliest = idx; 
          matchedToken = token; 
        }
      }
      
      if (earliest == null || matchedToken == null) { 
        spans.add(TextSpan(text: remaining, style: baseStyle)); 
        break; 
      }
      if (earliest > 0) {
        spans.add(TextSpan(text: remaining.substring(0, earliest), style: baseStyle));
      }
      
      final color = _wordColorMap[matchedToken] ?? Colors.yellow;
      final textStyleColor = (_multiHighlighterPalette.contains(color) && color != const Color(0xFFBA68C8)) 
          ? (context.isDark ? const Color(0xFF1A1625) : const Color(0xFF2D2540)) 
          : color;
 
      spans.add(TextSpan(
        text: remaining.substring(earliest, earliest + matchedToken.length), 
        style: baseStyle.copyWith(
          backgroundColor: color.withValues(alpha: 0.3), 
          color: textStyleColor,
          fontWeight: FontWeight.bold
        )
      ));
      remaining = remaining.substring(earliest + matchedToken.length);
    }
    return RichText(text: TextSpan(children: spans), textDirection: textDirection, textAlign: textAlign);
  }

  bool _isUrdu(String text) { 
    if (text.isEmpty) return false; 
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text); 
  }

  Map<String, Color> compileQueryColorMap(String rawQuery, String fullTextContent) {
    Map<String, Color> tokenMap = {};
    if (rawQuery.trim().isEmpty) return tokenMap;

    final String textLower = fullTextContent.toLowerCase();
    final List<String> rawTokens = rawQuery.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final List<String> finalProcessedTokens = [];

    int i = 0;
    while (i < rawTokens.length) {
      if (i < rawTokens.length - 1) {
        String pairedPhrase = "${rawTokens[i]} ${rawTokens[i + 1]}";
        if (textLower.contains(pairedPhrase.toLowerCase())) {
          finalProcessedTokens.add(pairedPhrase);
          i += 2;
          continue;
        }
      }
      finalProcessedTokens.add(rawTokens[i]);
      i++;
    }

    int paletteTracker = 0;
    for (String token in finalProcessedTokens) {
      if (token.isNotEmpty && !tokenMap.containsKey(token)) {
        tokenMap[token] = _multiHighlighterPalette[paletteTracker % _multiHighlighterPalette.length];
        paletteTracker++;
      }
    }
    return tokenMap;
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _isSearching = false; _query = ''; _wordColorMap = {}; _searchTokens = []; });
      return;
    }
    setState(() => _isSearching = true);
    
    // Fetch raw notes pool
    List<VaultFile> allNotes = await _getAllNotes();
    
    // STRICT FIX: Apply explicit folder bounds constraints if folderId is injected
    if (widget.folderId != null && widget.folderId!.isNotEmpty) {
      allNotes = allNotes.where((note) => note.folderId == widget.folderId).toList();
    }

    final matched = SearchHelper.searchFiles(query, allNotes, SearchMode.anyWord);
    
    final lowerQuery = query.toLowerCase();
    final filtered = matched.where((r) {
      switch (_activeFilter) {
        case 'title': return r.file.title.toLowerCase().contains(lowerQuery);
        case 'content': return r.file.description.toLowerCase().contains(lowerQuery);
        case 'english': return !_isUrdu('${r.file.title} ${r.file.description}');
        case 'urdu': return _isUrdu('${r.file.title} ${r.file.description}');
        default: return true;
      }
    }).toList();
    
    final combinedText = filtered.map((r) => '${r.file.title} ${r.file.description}').join(' ');
    _wordColorMap = compileQueryColorMap(query, combinedText);
    _searchTokens = _wordColorMap.keys.toList();
    filtered.sort((a, b) => b.totalMatches.compareTo(a.totalMatches));
    
    setState(() {
      _results = filtered;
      _isSearching = false;
    });
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

  Future<List<VaultFile>> _getAllNotes() async {
    return _hiveService.fileBox.values.map((f) => f.toEntity()).toList();
  }
}