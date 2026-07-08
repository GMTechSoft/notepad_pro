import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'dart:convert';
class ExportService {
  // Export note as plain text (.txt)
  static Future<void> exportAsTxt(VaultFile file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = file.title.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
      final fileName = sanitizedTitle.isEmpty ? 'Untitled_Note' : sanitizedTitle;
      final localFile = File('${tempDir.path}/${fileName}.txt');

      final List<int> bom = [0xEF, 0xBB, 0xBF];
    String content = "${file.title}\n\n${file.description}";
    if (file.bookName != null && file.bookName!.isNotEmpty) {
      content += "\n\nRef: ${file.bookName}, Vol ${file.volume ?? '1'}, Page ${file.pageNumber ?? '0'}";
    }
    final List<int> textBytes = utf8.encode(content);
    await localFile.writeAsBytes([...bom, ...textBytes]);

      await Share.shareXFiles([
        XFile(localFile.path),
      ], text: 'Exporting text file from NotePilot');
    } catch (e) {
      print('Export txt error: $e');
    }
  }

  // Export note as Word document (.doc) using RTF format
  static Future<String?> exportAsDocx(VaultFile file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = file.title.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
      final fileName = sanitizedTitle.isEmpty ? 'Untitled_Note' : sanitizedTitle;
      final localFile = File('${tempDir.path}/$fileName.docx');

      final sb = StringBuffer();
      sb.write(r'{\rtf1\ansi\deff0\uc0\pard\rtlpar ');
      // Title header block (Bold and Large font size)
      sb.write(r'{\b\fs32 ');
      sb.write(file.title.replaceAll('{', '\\{').replaceAll('}', '\\}'));
      sb.write(r'}\par\par');

      // Main note body content layout
      sb.write(file.description.replaceAll('{', '\\{').replaceAll('}', '\\}').replaceAll('\n', r'\par '));

      // Reference footer block integration
      if (file.bookName != null && file.bookName!.isNotEmpty) {
        sb.write(r'\par\par\b ----------\b0\par ');
        sb.write(r'{\i Reference: }');
        sb.write('${file.bookName} (Vol: ${file.volume ?? '1'}, Page: ${file.pageNumber ?? '0'})');
      } else if (file.videoTitle != null && file.videoTitle!.isNotEmpty) {
        sb.write(r'\par\par\b ----------\b0\par ');
        sb.write(r'{\i Video Reference: }');
        sb.write('${file.videoTitle} at ${file.videoRefHours ?? 0}h ${file.videoRefMinutes ?? 0}m');
      }
      sb.write(r'}');

      // Write file as bytes with UTF-8 BOM
      final List<int> bom = [0xEF, 0xBB, 0xBF];
      final List<int> contentBytes = utf8.encode(sb.toString());
      await localFile.writeAsBytes([...bom, ...contentBytes]);

      return localFile.path;
    } catch (e) {
      print('Export docx error: $e');
      return null;
    }
  }
}
