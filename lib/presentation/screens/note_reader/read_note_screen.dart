import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/core/utils/text_direction_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';

class ReadNoteScreen extends StatelessWidget {
  final VaultFile file;
  const ReadNoteScreen({super.key, required this.file});

  bool _isUrdu(String text) {
    if (text.trim().isEmpty) return false;
    int urduCount = 0;
    int totalLetters = 0;
    for (final rune in text.runes) {
      if (rune <= 32) continue;
      if (rune >= 48 && rune <= 57) continue;
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
              pw.Text(
                documentTitle,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                documentDesc,
                style: const pw.TextStyle(fontSize: 13),
              ),
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

    pw.Font? arabicFont;
    if (isTitleUrdu || isContentUrdu) {
      try {
        arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
        debugPrint('Arabic font loaded: OK');
      } catch (e) {
        debugPrint('Font load failed: $e');
        arabicFont = null;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format.copyWith(
          marginTop: 32,
          marginBottom: 32,
          marginLeft: 32,
          marginRight: 32,
        ),
        header: (pw.Context ctx) {
          if (ctx.pageNumber == 1) return pw.SizedBox();
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              documentTitle,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 10,
                color: PdfColors.grey400,
              ),
            ),
          );
        },
        footer: (pw.Context ctx) {
          final List<String> refParts = [];
          String refPrefix = "";

          if (currentFile.referenceType == ReferenceType.video) {
            refPrefix = "Video Ref: ";
            final String vTitle = (currentFile.videoTitle ?? '').trim();
            final String hours = currentFile.videoRefHours?.toString() ?? '0';
            final String minutes = currentFile.videoRefMinutes?.toString() ?? '0';
            final String seconds = currentFile.videoRefSeconds?.toString() ?? '0';
            if (vTitle.isNotEmpty) refParts.add(vTitle);
            refParts.add('${hours}h ${minutes}m ${seconds}s');
          } else if (currentFile.referenceType == ReferenceType.book) {
            refPrefix = "Book Ref: ";
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
            child: pw.Column(
              children: [
                if (formattedRef.isNotEmpty) ...[
                  pw.Container(
                    alignment: isContentUrdu ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                    padding: const pw.EdgeInsets.only(top: 8),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                    ),
                    child: pw.Text(
                      formattedRef,
                      textDirection: isContentUrdu ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                ],
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated via Notepad Pro',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                    ),
                    pw.Text(
                      'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        build: (pw.Context ctx) {
          return [
            // Title Block
            pw.Text(
              documentTitle,
              softWrap: true,
              textDirection: isTitleUrdu ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              textAlign: isTitleUrdu ? pw.TextAlign.right : pw.TextAlign.left,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),

            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            pw.SizedBox(height: 16),

            // Content Block
            pw.Text(
              documentDesc,
              softWrap: true,
              textDirection: isContentUrdu ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              textAlign: pw.TextAlign.justify,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 13,
                height: 1.5,
                lineSpacing: 2,
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  Future<void> _handlePrint(VaultFile currentFile) async {
    debugPrint('[PrintEngine] Directly firing native Android OS Print dialog...');
    
    await Printing.layoutPdf(
      name: currentFile.title.trim().isNotEmpty ? currentFile.title.replaceAll(' ', '_') : 'Note',
      format: PdfPageFormat.a4,
      onLayout: (PdfPageFormat format) async {
        try {
          final bytes = await generatePdfReport(format, currentFile);
          
          debugPrint('PDF bytes size: ${bytes.length}');
          if (bytes.length >= 4) {
            debugPrint('PDF starts with: ${String.fromCharCodes(bytes.take(4))}');
          }
          
          if (bytes.isEmpty) {
            throw Exception('PDF bytes empty');
          }
          return bytes;
        } catch (e) {
          debugPrint('onLayout error: $e');
          // Return minimal valid PDF so Android doesn't crash
          return await _buildFallbackPdf(currentFile);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilesCubit, FilesState>(
      builder: (context, state) {
        VaultFile currentFile = file;
        if (state is FilesLoadSuccess) {
          try {
            currentFile = state.files.firstWhere((f) => f.id == file.id);
          } catch (_) {}
        }

        final textDirection = TextDirectionUtils.getDirection(currentFile.description);
        final textAlign = TextDirectionUtils.getTextAlign(currentFile.description);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F0FF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF6C5CE7)),
              onPressed: () => context.pop(),
            ),
            title: Text(
              currentFile.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2540),
              ),
              textDirection: TextDirectionUtils.getDirection(currentFile.title),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_outlined, color: Color(0xFF6C5CE7)),
                onPressed: () => _handlePrint(currentFile),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF6C5CE7)),
                onPressed: () => context.push('/create-file', extra: currentFile),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: textDirection == TextDirection.rtl 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    currentFile.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2D2540),
                      height: 1.6,
                    ),
                    textDirection: textDirection,
                    textAlign: textAlign,
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE8E2F5), thickness: 0.5),
                  const SizedBox(height: 12),
                  _buildReferenceSection(context, currentFile),
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
                      onPressed: () => context.push('/create-file', extra: currentFile),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit Note"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePrint(currentFile),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text("Print"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6C5CE7),
                        side: const BorderSide(color: Color(0xFF6C5CE7)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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

  Widget _buildReferenceSection(BuildContext context, VaultFile currentFile) {
    String? referenceTitle;
    IconData? icon;
    String? details;

    if (currentFile.referenceType == ReferenceType.video) {
      referenceTitle = "Video Reference";
      icon = Icons.play_circle_outline;
      details = currentFile.videoTitle;
      if (currentFile.videoRefHours != null || currentFile.videoRefMinutes != null || currentFile.videoRefSeconds != null) {
        details = "${details ?? "Video"} at ${currentFile.videoRefHours ?? 0}h ${currentFile.videoRefMinutes ?? 0}m ${currentFile.videoRefSeconds ?? 0}s";
      }
    } else if (currentFile.referenceType == ReferenceType.book) {
      referenceTitle = "Book Reference";
      icon = Icons.book_outlined;
      details = currentFile.bookName;
      if (currentFile.authorName != null) details = "${details ?? "Book"} by ${currentFile.authorName}";
      
      List<String> parts = [];
      if ((currentFile.volume ?? '').isNotEmpty) parts.add("Vol: ${currentFile.volume}");
      if (currentFile.pageNumber != null) parts.add("Page: ${currentFile.pageNumber}");
      if (currentFile.lineNumber != null) parts.add("Line: ${currentFile.lineNumber}");
      
      if (parts.isNotEmpty) {
        details = "${details ?? ''}\n${parts.join(', ')}";
      }
    }

    if (referenceTitle == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF9B8DB8)),
            const SizedBox(width: 8),
            Text(
              referenceTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9B8DB8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                details ?? "N/A",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 4,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
