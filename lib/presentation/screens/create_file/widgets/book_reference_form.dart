import 'package:flutter/material.dart';

class BookReferenceForm extends StatelessWidget {
  final Function(String) onBookNameChanged;
  final Function(String) onAuthorNameChanged;
  final Function(String) onVolumeChanged;
  final Function(int) onPageNumberChanged;
  final Function(int) onLineNumberChanged;
  final String initialBookName;
  final String initialAuthorName;
  final String initialVolume;
  final int initialPageNumber;
  final int initialLineNumber;

  const BookReferenceForm({
    super.key,
    required this.onBookNameChanged,
    required this.onAuthorNameChanged,
    required this.onVolumeChanged,
    required this.onPageNumberChanged,
    required this.onLineNumberChanged,
    this.initialBookName = '',
    this.initialAuthorName = '',
    this.initialVolume = '',
    this.initialPageNumber = 0,
    this.initialLineNumber = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Book Reference', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialBookName,
          decoration: const InputDecoration(labelText: 'Book Name'),
          onChanged: onBookNameChanged,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialAuthorName,
          decoration: const InputDecoration(labelText: 'Author Name'),
          onChanged: onAuthorNameChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: initialVolume,
                decoration: const InputDecoration(labelText: 'Volume (e.g., I, II)'),
                 onChanged: onVolumeChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: initialPageNumber.toString(),
                decoration: const InputDecoration(labelText: 'Page Number'),
                keyboardType: TextInputType.number,
                onChanged: (value) => onPageNumberChanged(int.tryParse(value) ?? 0),
              ),
            ),
             const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: initialLineNumber.toString(),
                decoration: const InputDecoration(labelText: 'Line (optional)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => onLineNumberChanged(int.tryParse(value) ?? 0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
