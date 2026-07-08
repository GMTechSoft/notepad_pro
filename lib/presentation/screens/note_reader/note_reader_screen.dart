import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/services/pdf_service.dart';
import 'package:notepad_pro/core/utils/text_direction_utils.dart';

class NoteReaderScreen extends StatelessWidget {
  final VaultFile file;
  const NoteReaderScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final textDirection = TextDirectionUtils.getDirection(file.description);
    final textAlign = TextDirectionUtils.getTextAlign(file.description);

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
          file.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D2540),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Color(0xFF6C5CE7)),
            onPressed: () => PdfService.openFileAsPdf(context, file),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF6C5CE7)),
            onPressed: () => context.push('/create-file', extra: file),
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
                file.description,
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
              _buildReferenceSection(context),
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
                  onPressed: () => context.push('/create-file', extra: file),
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
                  onPressed: () => PdfService.openFileAsPdf(context, file),
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
  }

  Widget _buildReferenceSection(BuildContext context) {
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
      if (file.authorName != null) details = "${details ?? "Book"} by ${file.authorName}";
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
        Text(
          details ?? "N/A",
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6C5CE7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
