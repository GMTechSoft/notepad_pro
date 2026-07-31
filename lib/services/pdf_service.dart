import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';

class PdfService {
  static bool _isUrduText(String text) {
    if (text.trim().isEmpty) return false;
    int urduCount = 0;
    int totalCount = 0;
    for (final char in text.runes) {
      if (char > 32) {
        totalCount++;
        if ((char >= 0x0600 && char <= 0x06FF) ||
            (char >= 0xFB50 && char <= 0xFDFF) ||
            (char >= 0xFE70 && char <= 0xFEFF)) {
          urduCount++;
        }
      }
    }
    if (totalCount == 0) return false;
    return (urduCount / totalCount) > 0.3;
  }

  static Future<Uint8List> generatePdf({
    required String title,
    required String content,
    bool hasReference = false,
    String? referenceType,
    String? referenceDetail,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final doc = pw.Document();

    final String safeTitle = title.isNotEmpty ? title : 'Untitled';
    final String safeContent = content.isNotEmpty ? content : '(No content)';

    final isTitleUrdu = _isUrduText(safeTitle);
    final isContentUrdu = _isUrduText(safeContent);

    // Load Urdu font
    pw.Font? urduFont;
    try {
      final data =
          await rootBundle.load('assets/fonts/NotoNastaliqUrdu-Regular.ttf');
      urduFont = pw.Font.ttf(data);
    } catch (e) {
      debugPrint('Local font error: $e');
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format.copyWith(
            marginLeft: 25 * PdfPageFormat.mm,
            marginTop: 25 * PdfPageFormat.mm,
            marginRight: 25 * PdfPageFormat.mm,
            marginBottom: 25 * PdfPageFormat.mm),
        textDirection:
            isContentUrdu ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (pw.Context context) {
          return [
            // Title
            pw.Container(
              width: double.infinity,
              child: pw.Text(
                safeTitle,
                textDirection:
                    isTitleUrdu ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                textAlign: isTitleUrdu ? pw.TextAlign.right : pw.TextAlign.left,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: isTitleUrdu ? urduFont : null,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            pw.SizedBox(height: 12),

            // Content
            pw.Container(
              width: double.infinity,
              child: pw.Text(
                safeContent,
                textDirection:
                    isContentUrdu ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                textAlign: pw.TextAlign.justify,
                style: pw.TextStyle(
                  fontSize: 13,
                  lineSpacing: 6,
                  font: isContentUrdu ? urduFont : null,
                ),
              ),
            ),

            if (hasReference &&
                referenceDetail != null &&
                referenceDetail.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: isContentUrdu
                    ? pw.MainAxisAlignment.end
                    : pw.MainAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Text(referenceType ?? 'Reference',
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.blue700,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(referenceDetail,
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          ];
        },
        footer: (pw.Context ctx) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey400)),
        ),
      ),
    );

    return doc.save();
  }

  static Future<void> openFileAsPdf(
      BuildContext context, VaultFile item) async {
    if (item.description.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No content to display.')),
        );
      }
      return;
    }

    try {
      String? referenceDetail;
      if (item.referenceType == ReferenceType.video) {
        final title = item.videoTitle ?? "Video";
        final h = item.videoRefHours ?? 0;
        final m = item.videoRefMinutes ?? 0;
        final s = item.videoRefSeconds ?? 0;
        referenceDetail = '$title at ${h}h ${m}m ${s}s';
      } else if (item.referenceType == ReferenceType.book) {
        List<String> parts = [];
        if (item.bookName != null && item.bookName!.isNotEmpty) {
          parts.add(item.bookName!);
        }
        if (item.authorName != null && item.authorName!.isNotEmpty) {
          parts.add('by ${item.authorName}');
        }
        if (item.volume != null && item.volume!.isNotEmpty) {
          parts.add('Vol: ${item.volume}');
        }
        if (item.pageNumber != null) parts.add('Page: ${item.pageNumber}');
        if (item.lineNumber != null) parts.add('Line: ${item.lineNumber}');
        referenceDetail = parts.isEmpty ? "N/A" : parts.join(', ');
      }

      final pdfBytes = await generatePdf(
        title: item.title,
        content: item.description,
        hasReference: item.referenceType != ReferenceType.none,
        referenceType:
            item.referenceType == ReferenceType.video ? "Video" : "Book",
        referenceDetail: referenceDetail,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: '${item.title}.pdf',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }
}
