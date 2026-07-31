import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/core/utils/text_direction_utils.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/services/export_service.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

class ReadNoteScreen extends StatefulWidget {
  final VaultFile file;
  final String? highlightQuery;
  final List<String>? highlightWords;
  final String? searchMode;
  final Map<String, Color>? highlightColors;

  const ReadNoteScreen({
    super.key, 
    required this.file, 
    this.highlightQuery, 
    this.highlightWords, 
    this.searchMode, 
    this.highlightColors
  });

  @override
  State<ReadNoteScreen> createState() => _ReadNoteScreenState();
}

class _ReadNoteScreenState extends State<ReadNoteScreen> {
  late VaultFile _currentFile;
  String? _activeQuery;
  List<String> _syncedSearchTokens = [];
  Map<String, Color> _syncedWordColorMap = {};
  List<Map<String, dynamic>> _allMatches = [];
  int _currentMatchIndex = 0;
  int _totalMatches = 0;

  final ScrollController _scrollController = ScrollController();
  pw.Font? _cachedUrduRegular;
  pw.Font? _cachedUrduBold;
  bool _isFontLoading = true;
  String _selectedExportFormat = 'docx';

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;
    _preCacheUrduFonts();
    _activeQuery = widget.highlightQuery;

    if (widget.highlightColors != null && widget.highlightWords != null) {
      // Synchronize exact case-insensitive map structure passed down from the search pool context
      final orderedMap = <String, Color>{};
      for (var word in widget.highlightWords!) {
        final key = word.toLowerCase();
        if (widget.highlightColors!.containsKey(word)) {
          orderedMap[key] = widget.highlightColors![word]!;
        } else if (widget.highlightColors!.containsKey(key)) {
          orderedMap[key] = widget.highlightColors![key]!;
        }
      }
      _syncedWordColorMap = orderedMap;
      _syncedSearchTokens = orderedMap.keys.toList();
    }

    if (_syncedSearchTokens.isNotEmpty) {
      _totalMatches = _countTotalMatches(_currentFile.title, _syncedSearchTokens) +
          _countTotalMatches(_currentFile.description, _syncedSearchTokens);
      _buildMatchPositions(_currentFile.title, _currentFile.description);
    }
  }

  Future<void> _preCacheUrduFonts() async {
    try {
      final regularData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
      setState(() {
        _cachedUrduRegular = pw.Font.ttf(regularData);
        _cachedUrduBold = pw.Font.ttf(boldData);
        _isFontLoading = false;
      });
    } catch (e) {
      try {
        final regular = await PdfGoogleFonts.notoNaskhArabicRegular();
        final bold = await PdfGoogleFonts.notoNaskhArabicBold();
        setState(() {
          _cachedUrduRegular = regular;
          _cachedUrduBold = bold;
          _isFontLoading = false;
        });
      } catch (_) {
        setState(() {
          _isFontLoading = false;
        });
      }
    }
  }

  void _buildMatchPositions(String title, String description) {
    _allMatches = [];
    if (_syncedSearchTokens.isEmpty) return;
    for (int wi = 0; wi < _syncedSearchTokens.length; wi++) {
      final word = _syncedSearchTokens[wi].toLowerCase();
      int start = 0;
      final lowerTitle = title.toLowerCase();
      while (true) {
        final idx = lowerTitle.indexOf(word, start);
        if (idx == -1) break;
        _allMatches.add({'charPos': idx, 'wordIdx': wi});
        start = idx + word.length;
      }
      start = 0;
      final lowerDesc = description.toLowerCase();
      final offset = title.length + 1;
      while (true) {
        final idx = lowerDesc.indexOf(word, start);
        if (idx == -1) break;
        _allMatches.add({'charPos': offset + idx, 'wordIdx': wi});
        start = idx + word.length;
      }
    }
    _allMatches.sort((a, b) => (a['charPos'] as int).compareTo(b['charPos'] as int));
  }

  bool _isUrdu(String text) {
    if (text.trim().isEmpty) return false;
    int urduCount = 0;
    int totalLetters = 0;
    for (final rune in text.runes) {
      if (rune <= 32 || (rune >= 48 && rune <= 57)) continue;
      totalLetters++;
      if ((rune >= 0x0600 && rune <= 0x06FF) ||
          (rune >= 0x0750 && rune <= 0x077F) ||
          (rune >= 0xFB50 && rune <= 0xFDFF) ||
          (rune >= 0xFE70 && rune <= 0xFEFF)) {
        urduCount++;
      }
    }
    if (totalLetters == 0) return false;
    return (urduCount / totalLetters) >= 0.3;
  }

  int _countMatches(String text, String query) {
    if (query.isEmpty) return 0;
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int count = 0;
    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;
      count++;
      start = index + lowerQuery.length;
    }
    return count;
  }

  int _countTotalMatches(String text, List<String> words) {
    if (words.isEmpty) return 0;
    int total = 0;
    for (final w in words) {
      total += _countMatches(text, w);
    }
    return total;
  }

  void _nextMatch() {
    if (_totalMatches == 0) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _totalMatches;
    });
  }

  void _prevMatch() {
    if (_totalMatches == 0) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _totalMatches) % _totalMatches;
    });
  }

  void _clearHighlight() {
    setState(() {
      _activeQuery = null;
      _totalMatches = 0;
      _currentMatchIndex = 0;
      _allMatches = [];
      _syncedSearchTokens = [];
      _syncedWordColorMap = {};
    });
  }

  Widget _buildSyncedMultiHighlight({
    required String text,
    required TextStyle baseStyle,
    required TextDirection textDirection,
    required TextAlign textAlign,
  }) {
    if (_syncedSearchTokens.isEmpty || _syncedWordColorMap.isEmpty) {
      return Text(text, style: baseStyle, textDirection: textDirection, textAlign: textAlign);
    }
    final spans = <TextSpan>[];
    String remaining = text;
    
    while (remaining.isNotEmpty) {
      int? earliest; 
      String? matchedToken;
      
      for (final token in _syncedSearchTokens) {
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
      
      final color = _syncedWordColorMap[matchedToken] ?? Colors.yellow;
      final textStyleColor = (color == const Color(0xFFBA68C8)) ? Colors.white : const Color(0xFF2D2540);

      spans.add(TextSpan(
        text: remaining.substring(earliest, earliest + matchedToken.length), 
        style: baseStyle.copyWith(
          backgroundColor: color.withValues(alpha: 0.35), 
          color: textStyleColor,
          fontWeight: FontWeight.bold
        )
      ));
      remaining = remaining.substring(earliest + matchedToken.length);
    }
    return RichText(text: TextSpan(children: spans), textDirection: textDirection, textAlign: textAlign);
  }

  // ==================== PDF Printing Engine ====================
  Future<Uint8List> _buildFallbackPdf(VaultFile currentFile) async {
    final doc = pw.Document();
    final String documentTitle = currentFile.title.trim().isEmpty ? 'Untitled' : currentFile.title.trim();
    final String documentDesc = currentFile.description.trim().isEmpty ? '(No content)' : currentFile.description.trim();
    doc.addPage(
      pw.Page(
        build: (_) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(documentTitle, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text(documentDesc, style: const pw.TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  Future<Uint8List> generatePdfReport(PdfPageFormat format, VaultFile currentFile) async {
    final doc = pw.Document();
    final String documentTitle = currentFile.title.trim().isEmpty ? 'Untitled' : currentFile.title.trim();
    final String documentDesc = currentFile.description.trim().isEmpty ? '(No content)' : currentFile.description.trim();
    final bool isTitleUrdu = _isUrdu(documentTitle);
    final bool isContentUrdu = _isUrdu(documentDesc);
    final bool isAnyUrdu = isTitleUrdu || isContentUrdu;

    final pw.Font? fallbackRegular = _cachedUrduRegular;
    final pw.Font? fallbackBold = _cachedUrduBold;
    final pw.TextDirection direction = isContentUrdu ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final pw.ThemeData dynamicTheme = pw.ThemeData.withFont(
      base: fallbackRegular,
      bold: fallbackBold,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: format.copyWith(marginTop: 32, marginBottom: 32, marginLeft: 32, marginRight: 32),
        theme: isAnyUrdu ? dynamicTheme : null,
        header: (pw.Context ctx) {
          if (ctx.pageNumber == 1) return pw.SizedBox();
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              documentTitle,
              textDirection: direction,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                font: fallbackBold ?? fallbackRegular,
                fontSize: 10,
                color: PdfColors.grey400,
              ),
            ),
          );
        },
        footer: (pw.Context ctx) {
          final List<String> refParts = [];
          String refPrefix = '';
          if (currentFile.referenceType == ReferenceType.video) {
            refPrefix = 'Video Ref: ';
            final String vTitle = (currentFile.videoTitle ?? '').trim();
            final String hours = currentFile.videoRefHours?.toString() ?? '0';
            final String minutes = currentFile.videoRefMinutes?.toString() ?? '0';
            final String seconds = currentFile.videoRefSeconds?.toString() ?? '0';
            if (vTitle.isNotEmpty) refParts.add(vTitle);
            refParts.add('${hours}h ${minutes}m ${seconds}s');
          } else if (currentFile.referenceType == ReferenceType.book) {
            refPrefix = 'Book Ref: ';
            if ((currentFile.bookName ?? '').trim().isNotEmpty) refParts.add(currentFile.bookName!.trim());
            if ((currentFile.authorName ?? '').trim().isNotEmpty) refParts.add(currentFile.authorName!.trim());
            if ((currentFile.volume ?? '').trim().isNotEmpty) refParts.add('Vol: ${currentFile.volume!.trim()}');
            if (currentFile.pageNumber != null) refParts.add('Page: ${currentFile.pageNumber}');
            if (currentFile.lineNumber != null) refParts.add('Line: ${currentFile.lineNumber}');
          }
          final String formattedRef = refParts.isNotEmpty ? '$refPrefix${refParts.join(', ')}' : '';
          return pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Column(children: [
              if (formattedRef.isNotEmpty) ...[
                pw.Container(
                  alignment: isContentUrdu ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                  padding: const pw.EdgeInsets.only(top: 8),
                  decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                  child: pw.Text(
                    formattedRef,
                    textDirection: direction,
                    style: pw.TextStyle(font: fallbackRegular, fontSize: 9, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Generated via NotePilot', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
                pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
              ]),
            ]),
          );
        },
        build: (pw.Context ctx) => [
          pw.Container(
            width: double.infinity,
            alignment: isTitleUrdu ? pw.Alignment.topRight : pw.Alignment.topLeft,
            child: pw.Text(
              documentTitle,
              textDirection: direction,
              textAlign: isTitleUrdu ? pw.TextAlign.right : pw.TextAlign.left,
              style: pw.TextStyle(
                font: fallbackBold ?? fallbackRegular,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400, thickness: 0.5),
          pw.SizedBox(height: 16),
          pw.Text(
            documentDesc,
            softWrap: true,
            textDirection: direction,
            textAlign: pw.TextAlign.justify,
            style: pw.TextStyle(font: fallbackRegular, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _handlePrint(VaultFile currentFile) async {
    if (_isFontLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preparing the Urdu layout. Please wait...")),
      );
      return;
    }
    await Printing.layoutPdf(
      name: currentFile.title.trim().isNotEmpty ? currentFile.title.replaceAll(' ', '_') : 'Note',
      format: PdfPageFormat.a4,
      onLayout: (PdfPageFormat format) async {
        try {
          final bytes = await generatePdfReport(format, currentFile);
          if (bytes.isEmpty) throw Exception('PDF bytes empty');
          return bytes;
        } catch (_) {
          return await _buildFallbackPdf(currentFile);
        }
      },
    );
  }

  // ==================== Export Mechanics Block ====================
  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.scaffoldBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sheetSetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 9, bottom: 4),
                  width: 32, height: 4,
                  decoration: BoxDecoration(color: context.border, borderRadius: const BorderRadius.all(Radius.circular(2))),
                ),
                Text("FORMAT CHUNEIN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.subText, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      _fmtOption(setState: sheetSetState, value: 'docx', iconBg: const Color(0xFFE3F2FD), iconColor: const Color(0xFF0C447C), icon: Icons.article_outlined, name: "Word (.docx)", desc: "MS Word mein khule — formatting ke saath"),
                      const SizedBox(height: 8),
                      _fmtOption(setState: sheetSetState, value: 'txt', iconBg: const Color(0xFFEAF3DE), iconColor: const Color(0xFF27500A), icon: Icons.text_snippet_outlined, name: "Plain Text (.txt)", desc: "Simple text — kisi bhi app mein khule"),
                      const SizedBox(height: 8),
                      _fmtOption(setState: sheetSetState, value: 'pdf', iconBg: const Color(0xFFFCEBEB), iconColor: const Color(0xFFA32D2D), icon: Icons.picture_as_pdf_outlined, name: "PDF (.pdf)", desc: "Print ya share ke liye ready"),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _exportNote(_selectedExportFormat);
                          },
                          icon: const Icon(Icons.share_outlined, size: 16),
                          label: const Text("Export"),
                          style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(backgroundColor: context.highlightBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 11)),
                          child: Text("Cancel", style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fmtOption({
    required StateSetter setState,
    required String value,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String name,
    required String desc,
  }) {
    final bool isSelected = _selectedExportFormat == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedExportFormat = value;
        this.setState(() {});
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? context.highlightBg : (context.isDark ? const Color(0xFF252033) : const Color(0xFFF8F6FF)),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: isSelected ? context.primaryColor : context.border, width: isSelected ? 1 : 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.primaryText)),
                  Text(desc, style: TextStyle(fontSize: 10, color: context.subText)),
                ],
              ),
            ),
            Container(
              width: 17, height: 17,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? context.primaryColor : context.border, width: 1.5)),
              child: isSelected ? Center(child: Icon(Icons.check, size: 12, color: context.primaryColor)) : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportNote(String format) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(context.primaryColor)),
              const SizedBox(height: 12),
              Text("Preparing your file...", style: TextStyle(fontSize: 13, color: context.primaryText)),
            ],
          ),
        ),
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      if (!mounted) return;
      final safeName = _currentFile.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim().isEmpty
          ? 'note'
          : _currentFile.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();

      if (format == 'txt') {
        await ExportService.exportAsTxt(_currentFile);
        if (!mounted) return;
        Navigator.pop(context);
        return;
      } else if (format == 'docx') {
        final filePath = await ExportService.exportAsDocx(_currentFile);
        if (!mounted) return;
        Navigator.pop(context);
        if (filePath != null) {
          await OpenFile.open(filePath);
        }
        return;
      } else if (format == 'pdf') {
        if (_isFontLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Preparing the Urdu layout. Please wait...")),
          );
          return;
        }
        final docBytes = await generatePdfReport(PdfPageFormat.a4, _currentFile);
        if (!mounted) return;
        final pdfFile = File('${tempDir.path}/$safeName.pdf');
        await pdfFile.writeAsBytes(docBytes);
        if (!mounted) return;
        
        Navigator.pop(context);
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;

        await Share.shareXFiles([XFile(pdfFile.path, mimeType: 'application/pdf')], subject: _currentFile.title);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to export: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilesCubit, FilesState>(
      builder: (context, state) {
        if (state is FilesLoadSuccess) {
          try {
            _currentFile = state.files.firstWhere((f) => f.id == widget.file.id);
          } catch (_) {}
        }
        final textDirection = TextDirectionUtils.getDirection(_currentFile.description);
        final textAlign = TextDirectionUtils.getTextAlign(_currentFile.description);
        final isTitleRTL = TextDirectionUtils.getDirection(_currentFile.title) == TextDirection.rtl;

        return Scaffold(
          backgroundColor: context.scaffoldBg,
          appBar: AppBar(
            backgroundColor: context.cardBg,
            elevation: 0,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: context.primaryColor), onPressed: () => context.pop()),
            title: _buildSyncedMultiHighlight(
              text: _currentFile.title, 
              baseStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: context.primaryText), 
              textDirection: TextDirectionUtils.getDirection(_currentFile.title),
              textAlign: TextAlign.left
            ),
            actions: [
              IconButton(icon: Icon(Icons.print_outlined, color: context.primaryColor), onPressed: () => _handlePrint(_currentFile)),
              IconButton(icon: Icon(Icons.edit_outlined, color: context.primaryColor), onPressed: () => context.push('/create-file', extra: _currentFile)),
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.border, width: 0.5)),
              child: Column(
                crossAxisAlignment: textDirection == TextDirection.rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (_activeQuery != null && _totalMatches > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: context.highlightBg, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(child: Text('"$_activeQuery" - $_totalMatches matches', style: TextStyle(fontSize: 12, color: context.primaryColor))),
                          IconButton(icon: Icon(Icons.chevron_left, size: 20, color: context.primaryColor), onPressed: _prevMatch),
                          IconButton(icon: Icon(Icons.chevron_right, size: 20, color: context.primaryColor), onPressed: _nextMatch),
                          IconButton(icon: Icon(Icons.close, size: 20, color: context.primaryColor), onPressed: _clearHighlight),
                        ],
                      ),
                    ),
                  
                  // Title Highlight (Using True Multi-Color Parser)
                  _buildSyncedMultiHighlight(
                    text: _currentFile.title,
                    baseStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.primaryText),
                    textDirection: TextDirectionUtils.getDirection(_currentFile.title),
                    textAlign: isTitleRTL ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),
                  
                  // Content Description Highlight (Using True Multi-Color Parser)
                  _buildSyncedMultiHighlight(
                    text: _currentFile.description,
                    baseStyle: TextStyle(fontSize: 16, color: context.primaryText, height: 1.6),
                    textDirection: textDirection,
                    textAlign: textAlign,
                  ),
                  const SizedBox(height: 24),
                  Divider(color: context.border, thickness: 0.5),
                  const SizedBox(height: 12),
                  _buildReferenceSection(context, _currentFile),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/create-file', extra: _currentFile),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit Note"),
                      style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePrint(_currentFile),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text("Print"),
                      style: OutlinedButton.styleFrom(foregroundColor: context.primaryColor, side: BorderSide(color: context.primaryColor), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showExportSheet,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text("Export"),
                      style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildReferenceSection(BuildContext context, VaultFile file) {
    String? referenceTitle;
    IconData? icon;
    String? details;
    if (file.referenceType == ReferenceType.video) {
      referenceTitle = "Video Reference";
      icon = Icons.play_circle_outline;
      details = file.videoTitle;
      if (file.videoRefHours != null || file.videoRefMinutes != null || file.videoRefSeconds != null) {
        details = "${details ?? "Video"} at ${file.videoRefHours ?? 0}h ${file.videoRefMinutes ?? 0}m ${file.videoRefSeconds ?? 0}s";
      }
    } else if (file.referenceType == ReferenceType.book) {
      referenceTitle = "Book Reference";
      icon = Icons.book_outlined;
      details = file.bookName;
      if (file.authorName != null && file.authorName!.isNotEmpty) {
        details = "${details ?? "Book"} by ${file.authorName}";
      }
      if (file.volume != null && file.volume!.isNotEmpty) {
        details = "${details ?? "Book"} (Vol: ${file.volume})";
      }
      if (file.pageNumber != null) {
        details = "${details ?? "Book"} - Page: ${file.pageNumber}";
      }
    }
    if (referenceTitle == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: context.subText),
            const SizedBox(width: 8),
            Text(referenceTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.subText)),
          ],
        ),
        const SizedBox(height: 4),
        Text(details ?? "N/A", style: TextStyle(fontSize: 14, color: context.primaryColor, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
