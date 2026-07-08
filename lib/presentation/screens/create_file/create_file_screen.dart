import 'dart:math';

import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart';
import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';

class CreateFileScreen extends StatefulWidget {
  final String? folderId;
  final VaultFile? initialFile;
  const CreateFileScreen({super.key, this.folderId, this.initialFile});

  @override
  State<CreateFileScreen> createState() => _CreateFileScreenState();
}

class _CreateFileScreenState extends State<CreateFileScreen> {

  bool _hasCreatedAuto = false; // tracks if auto-save created a new file
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
bool _isSaving = false; // guard against concurrent saves
late final String _stableFileId; // stable ID for this session
late final AppLifecycleListener _lifecycleListener; // listener for app lifecycle events
// Missing fields restored
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _title = '';
  String _description = '';

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  bool _isTitleUrdu = false;
  bool _isDescUrdu = false;
  bool _showReference = false;
  bool _addReference = false;
  late ReferenceType _referenceType;
  late String _videoTitle;
  late int _videoHours;
  late int _videoMinutes;
  late int _videoSeconds;
  late TextEditingController _hourCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _secCtrl;
  late TextEditingController _bookTitleController;
  late String _authorName;
  late TextEditingController _volumeCtrl;
  late TextEditingController _pageCtrl;
  late TextEditingController _lineCtrl;

  // FocusNodes for keyboard management
  final FocusNode _volumeFocus = FocusNode();
  final FocusNode _pageFocus = FocusNode();
  final FocusNode _lineFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final file = widget.initialFile;
    _titleController = TextEditingController(text: file?.title ?? '');
    _descriptionController = TextEditingController(text: file?.description ?? '');

    // Freeze a stable ID for this editing session
    _stableFileId = widget.initialFile?.id ?? const Uuid().v4();

    // Initialize AppLifecycleListener to trigger save when app goes to background
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
          _performSecureSaveAndSync(isManualSave: false);
        }
      },
    );

    _addReference = file?.referenceType != null &&
        file?.referenceType != ReferenceType.none;
    _referenceType = file?.referenceType ?? ReferenceType.book;

    _videoTitle = file?.videoTitle ?? '';
    _videoHours = file?.videoRefHours ?? 0;
    _videoMinutes = file?.videoRefMinutes ?? 0;
    _videoSeconds = file?.videoRefSeconds ?? 0;

    _hourCtrl =
        TextEditingController(text: _videoHours.toString().padLeft(2, '0'));
    _minCtrl =
        TextEditingController(text: _videoMinutes.toString().padLeft(2, '0'));
    _secCtrl =
        TextEditingController(text: _videoSeconds.toString().padLeft(2, '0'));

    _bookTitleController = TextEditingController(text: file?.bookName ?? '');
    _authorName = file?.authorName ?? '';

    _volumeCtrl = TextEditingController(text: file?.volume ?? '');
    _pageCtrl =
        TextEditingController(text: file?.pageNumber?.toString() ?? '1');
    _lineCtrl = TextEditingController(text: file?.lineNumber?.toString() ?? '');

    // Validate min page value
    _pageCtrl.addListener(() {
      final val = int.tryParse(_pageCtrl.text);
      if (val != null && val < 1) {
        _pageCtrl.text = '1';
        _pageCtrl.selection =
            TextSelection.collapsed(offset: _pageCtrl.text.length);
      }
    });
  }

  // ---------------------------------------------------------------------
  // Auto‑save handling
  // ---------------------------------------------------------------------


  /// Unified save method used by both auto‑save and manual save actions.
Future<void> _performSecureSaveAndSync({required bool isManualSave}) async {
  // Do nothing if both title and description are empty.
  if (_titleController.text.trim().isEmpty && _descriptionController.text.trim().isEmpty) return;

    // Guard against concurrent saves.
  if (_isSaving) return;
  _isSaving = true;
  // Build the VaultFile instance with all current field values.
    final finalFile = VaultFile(
      id: widget.initialFile?.id ?? _stableFileId,
      folderId: widget.initialFile?.folderId ?? widget.folderId,
      title: _titleController.text.isEmpty ? "Untitled Note" : _titleController.text,
      description: _descriptionController.text,
      createdAt: widget.initialFile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    referenceType: _addReference ? _referenceType : ReferenceType.none,
    videoTitle: _addReference && _referenceType == ReferenceType.video ? _videoTitle : null,
    videoRefHours: _addReference && _referenceType == ReferenceType.video ? _videoHours : null,
    videoRefMinutes: _addReference && _referenceType == ReferenceType.video ? _videoMinutes : null,
    videoRefSeconds: _addReference && _referenceType == ReferenceType.video ? _videoSeconds : null,
    bookName: _addReference && _referenceType == ReferenceType.book ? _bookTitleController.text : null,
    authorName: _addReference && _referenceType == ReferenceType.book ? _authorName : null,
    volume: _addReference && _referenceType == ReferenceType.book ? (_volumeCtrl.text.isEmpty ? null : _volumeCtrl.text) : null,
    pageNumber: _addReference && _referenceType == ReferenceType.book ? int.tryParse(_pageCtrl.text) ?? 1 : null,
    lineNumber: _addReference && _referenceType == ReferenceType.book ? int.tryParse(_lineCtrl.text) : null
  );

  try {
    if (widget.initialFile == null && !_hasCreatedAuto) {
      // New file – use createFile to insert into local DB.
      await context.read<FilesCubit>().createFile(
        folderId: widget.folderId,
        title: finalFile.title,
        description: finalFile.description,
        referenceType: finalFile.referenceType,
        videoTitle: finalFile.videoTitle,
        videoRefHours: finalFile.videoRefHours,
        videoRefMinutes: finalFile.videoRefMinutes,
        videoRefSeconds: finalFile.videoRefSeconds,
        bookName: finalFile.bookName,
        authorName: finalFile.authorName,
        volume: finalFile.volume,
        pageNumber: finalFile.pageNumber,
        lineNumber: finalFile.lineNumber,
      );
      _hasCreatedAuto = true; // mark creation done.
    } else {
      // Existing or already created file – update.
      await context.read<FilesCubit>().updateFile(finalFile);
    }

      // If auto‑sync is enabled and this is a manual save, trigger a single file upload to Google Drive.
      final configBox = Hive.box('settings');
      final bool isAutoSyncEnabled = (configBox.get('auto_sync', defaultValue: false) as bool);
      if (isAutoSyncEnabled) {
        await context.read<SyncCubit>().syncNow();
      }
    } catch (error, stackTrace) {
      // Log any error – keep UI responsive.
      print('Database or Cloud pipeline handling error: $error');
      print(stackTrace);
    } finally {
    // Reset saving guard.
    _isSaving = false;
    // If this was an explicit manual save, navigate back.
    if (isManualSave && mounted) {
      Navigator.pop(context);
    }
  }
}

  @override
  void dispose() {
    // Dispose lifecycle listener
    _lifecycleListener.dispose();

    // Force a final synchronous save to ensure all data is persisted and synced
    _performSecureSaveAndSync(isManualSave: false);

    // Dispose controllers and focus nodes
    _titleController.dispose();
    _descriptionController.dispose();
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _secCtrl.dispose();
    _bookTitleController.dispose();
    _volumeCtrl.dispose();
    _pageCtrl.dispose();
    _lineCtrl.dispose();
    _volumeFocus.dispose();
    _pageFocus.dispose();
    _lineFocus.dispose();
    super.dispose();
  }

  bool _isUrdu(String text) {
    if (text.isEmpty) return false;
    final urduRegex = RegExp(r'[\u0600-\u06FF]');
    return urduRegex.hasMatch(text);
  }

  Future<void> _saveFile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        final currentTitle = _titleController.text;
        final currentBookName = _bookTitleController.text;

        final String? volume =
            _volumeCtrl.text.isEmpty ? null : _volumeCtrl.text;
        final int page = int.tryParse(_pageCtrl.text) ?? 1;
        final int? line =
            _lineCtrl.text.isEmpty ? null : int.tryParse(_lineCtrl.text);

        final int vHours = int.tryParse(_hourCtrl.text) ?? 0;
        final int vMinutes = int.tryParse(_minCtrl.text) ?? 0;
        final int vSeconds = int.tryParse(_secCtrl.text) ?? 0;

        if (widget.initialFile != null) {
          final updatedFile = widget.initialFile!.copyWith(
            title: currentTitle,
            description: _description,
            referenceType: _addReference ? _referenceType : ReferenceType.none,
            videoTitle: _addReference && _referenceType == ReferenceType.video
                ? _videoTitle
                : null,
            videoRefHours:
                _addReference && _referenceType == ReferenceType.video
                    ? vHours
                    : null,
            videoRefMinutes:
                _addReference && _referenceType == ReferenceType.video
                    ? vMinutes
                    : null,
            videoRefSeconds:
                _addReference && _referenceType == ReferenceType.video
                    ? vSeconds
                    : null,
            bookName: _addReference && _referenceType == ReferenceType.book
                ? currentBookName
                : null,
            authorName: _addReference && _referenceType == ReferenceType.book
                ? _authorName
                : null,
            volume: _addReference && _referenceType == ReferenceType.book
                ? volume
                : null,
            pageNumber: _addReference && _referenceType == ReferenceType.book
                ? page
                : null,
            lineNumber: _addReference && _referenceType == ReferenceType.book
                ? line
                : null,
            updatedAt: DateTime.now(),
          );
          await context.read<FilesCubit>().updateFile(updatedFile);
        } else {
          await context.read<FilesCubit>().createFile(
                folderId: widget.folderId,
                title: currentTitle,
                description: _description,
                referenceType:
                    _addReference ? _referenceType : ReferenceType.none,
                videoTitle:
                    _addReference && _referenceType == ReferenceType.video
                        ? _videoTitle
                        : null,
                videoRefHours:
                    _addReference && _referenceType == ReferenceType.video
                        ? vHours
                        : null,
                videoRefMinutes:
                    _addReference && _referenceType == ReferenceType.video
                        ? vMinutes
                        : null,
                videoRefSeconds:
                    _addReference && _referenceType == ReferenceType.video
                        ? vSeconds
                        : null,
                bookName: _addReference && _referenceType == ReferenceType.book
                    ? currentBookName
                    : null,
                authorName:
                    _addReference && _referenceType == ReferenceType.book
                        ? _authorName
                        : null,
                volume: _addReference && _referenceType == ReferenceType.book
                    ? volume
                    : null,
                pageNumber:
                    _addReference && _referenceType == ReferenceType.book
                        ? page
                        : null,
                lineNumber:
                    _addReference && _referenceType == ReferenceType.book
                        ? line
                        : null,
              );
        }
        if (mounted) context.pop(true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _performSecureSaveAndSync(isManualSave: false);
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0FF),
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            const SizedBox(height: 10),
            _buildFieldLabel("File title *"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8D0F0), width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: TextFormField(
                controller: _titleController,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textDirection: _isUrdu(_titleController.text)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                textAlign: _isUrdu(_titleController.text)
                    ? TextAlign.right
                    : TextAlign.left,
                onChanged: (val) => setState(() {}),
                validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
                decoration: const InputDecoration(
                  hintText: 'File ka naam likhein...',
                  hintStyle: TextStyle(color: Color(0xFFB0A0CC), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF2D2540)),
              ),
            ),
            const SizedBox(height: 10),
            _buildFieldLabel("Description"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8D0F0), width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textDirection: _isUrdu(_descriptionController.text) ? TextDirection.rtl : TextDirection.ltr,
                textAlign: _isUrdu(_descriptionController.text) ? TextAlign.right : TextAlign.left,
                onChanged: (val) => setState(() {}),
                validator: (val) => null,
                decoration: const InputDecoration(
                  hintText: "Apni notes yahan likhein...",
                  hintStyle: TextStyle(color: Color(0xFFB0A0CC), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF2D2540)),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE8E2F5), thickness: 0.5),
            const SizedBox(height: 16),

            // Reference Toggle Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8D0F0), width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Reference add karein",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D2540)),
                        ),
                        const Text(
                          "Book ya video link karein (optional)",
                          style:
                              TextStyle(fontSize: 10, color: Color(0xFF9B8DB8)),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _addReference,
                    onChanged: (val) => setState(() => _addReference = val),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF6C5CE7),
                  ),
                ],
              ),
            ),

            if (_addReference) ...[
              const SizedBox(height: 16),
              // Fix A — Segmented Control with better padding
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border:
                      Border.all(color: const Color(0xFFD8D0F0), width: 0.5),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(children: [
                  _buildTab(
                    icon: Icons.play_circle_outline,
                    label: "Video",
                    isActive: _referenceType == ReferenceType.video,
                    onTap: () =>
                        setState(() => _referenceType = ReferenceType.video),
                  ),
                  _buildTab(
                    icon: Icons.menu_book_outlined,
                    label: "Book",
                    isActive: _referenceType == ReferenceType.book,
                    onTap: () =>
                        setState(() => _referenceType = ReferenceType.book),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Reference Details
              if (_referenceType == ReferenceType.book) _buildBookSection(),
              if (_referenceType == ReferenceType.video) _buildVideoSection(),

              const SizedBox(height: 20),
              // Info Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Color(0xFF6C5CE7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _referenceType == ReferenceType.video
                            ? "Timestamp se directly us waqt pe jump kar sakte hain"
                            : "Reference save hone ke baad search mein dikh sakta hai",
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF534AB7)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    ));
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final bool isSaveDisabled = _titleController.text.trim().isEmpty;

    return AppBar(
      backgroundColor: const Color(0xFFF5F0FF),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          _buildCircleButton(
            icon: Icons.arrow_back,
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          const Text(
            "Create new file",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2540)),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: (isSaveDisabled || _isLoading) ? null : () async => await _performSecureSaveAndSync(isManualSave: true),
            icon: _isLoading
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, size: 14, color: Colors.white),
            label: const Text("Save",
                style: TextStyle(color: Colors.white, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              disabledBackgroundColor: Colors.grey.shade400,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9F8),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6C5CE7)),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 10),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9B8DB8),
            fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required Function(String?) onSaved,
    Function(String)? onChanged,
    String? initialValue,
    String? Function(String?)? validator,
    int maxLines = 1,
    double? minHeight,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      constraints:
          minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8D0F0), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: TextFormField(
        initialValue: initialValue,
        onSaved: onSaved,
        onChanged: onChanged,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB0A0CC), fontSize: 13),
          border: InputBorder.none,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13, color: Color(0xFF2D2540)),
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6C5CE7) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 13,
                  color: isActive ? Colors.white : const Color(0xFF9B8DB8)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF9B8DB8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.book_outlined, "Book reference",
            color: const Color(0xFF6C5CE7), bgColor: const Color(0xFFEDE9F8)),
        _buildFieldLabel("Book ka naam *"),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD8D0F0), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: TextFormField(
            controller: _bookTitleController,
            maxLines: null,
            minLines: 1,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            validator: (val) => (_addReference &&
                    _referenceType == ReferenceType.book &&
                    (val?.isEmpty ?? true))
                ? 'Required'
                : null,
            decoration: const InputDecoration(
              hintText: 'e.g. Aab-e-Hayat',
              hintStyle: TextStyle(color: Color(0xFFB0A0CC), fontSize: 13),
              border: InputBorder.none,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF2D2540)),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            const Text("Volume / Page / Line",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9B8DB8))),
            const SizedBox(height: 6),
            // 3 boxes in a row
            Row(children: [
              Expanded(
                  child: _buildNumBox(
                label: "Volume",
                unit: "optional",
                controller: _volumeCtrl,
                focusNode: _volumeFocus,
                minVal: 0,
                isOptional: true,
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildNumBox(
                label: "Page",
                unit: "number",
                controller: _pageCtrl,
                focusNode: _pageFocus,
                minVal: 1,
                isOptional: false,
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildNumBox(
                label: "Line",
                unit: "optional",
                controller: _lineCtrl,
                focusNode: _lineFocus,
                minVal: 0,
                isOptional: true,
              )),
            ]),
          ],
        ),
        const SizedBox(height: 10),
        _buildFieldLabel("Musannif (Author)"),
        _buildTextField(
          hint: "e.g. Umera Ahmed",
          initialValue: _authorName,
          onSaved: (val) => _authorName = val ?? '',
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.play_circle_outline, "Video reference",
            color: const Color(0xFFC0392B), bgColor: const Color(0xFFFDECEA)),
        _buildFieldLabel("Video title *"),
        _buildTextField(
          hint: "e.g. Bayan No. 45 — Mufti Tariq...",
          initialValue: _videoTitle,
          onSaved: (val) => _videoTitle = val ?? '',
          validator: (val) => (_addReference &&
                  _referenceType == ReferenceType.video &&
                  (val?.isEmpty ?? true))
              ? 'Required'
              : null,
        ),
        const SizedBox(height: 16),
        _buildFieldLabel("Timestamp — video ka waqt"),
        Row(children: [
          _tsBox("Ghante", "hours", _hourCtrl, 99),
          const SizedBox(width: 6),
          _tsBox("Minute", "min", _minCtrl, 59),
          const SizedBox(width: 6),
          _tsBox("Second", "sec", _secCtrl, 59),
        ]),
      ],
    );
  }

  Widget _tsBox(
      String label, String unit, TextEditingController controller, int max) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0FF),
          border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF9B8DB8))),
          ),
          Row(children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  int val = int.tryParse(controller.text) ?? 0;
                  if (val > 0) {
                    val--;
                    controller.text = val.toString().padLeft(2, '0');
                    setState(() {
                      if (unit == "hours") _videoHours = val;
                      if (unit == "min") _videoMinutes = val;
                      if (unit == "sec") _videoSeconds = val;
                    });
                  }
                },
                child: Container(
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9F8),
                    borderRadius:
                        BorderRadius.only(bottomLeft: Radius.circular(9)),
                  ),
                  child: const Center(
                    child: Text("-",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6C5CE7))),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 45,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2540)),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (value) {
                  if (value.isEmpty) return;
                  int val = int.tryParse(value) ?? 0;
                  if (val > max) {
                    val = max;
                    controller.text = val.toString().padLeft(2, '0');
                    controller.selection =
                        TextSelection.collapsed(offset: controller.text.length);
                  }
                  setState(() {
                    if (unit == "hours") _videoHours = val;
                    if (unit == "min") _videoMinutes = val;
                    if (unit == "sec") _videoSeconds = val;
                  });
                },
                onFieldSubmitted: (value) {
                  final val = int.tryParse(value) ?? 0;
                  controller.text = val.toString().padLeft(2, '0');
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  int val = int.tryParse(controller.text) ?? 0;
                  if (val < max) {
                    val++;
                    controller.text = val.toString().padLeft(2, '0');
                    setState(() {
                      if (unit == "hours") _videoHours = val;
                      if (unit == "min") _videoMinutes = val;
                      if (unit == "sec") _videoSeconds = val;
                    });
                  }
                },
                child: Container(
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C5CE7),
                    borderRadius:
                        BorderRadius.only(bottomRight: Radius.circular(9)),
                  ),
                  child: const Center(
                    child: Text("+",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // Helper to step value up or down:
  void _stepValue(TextEditingController ctrl, int delta, {int min = 0}) {
    final cur = int.tryParse(ctrl.text) ?? min;
    final next = (cur + delta).clamp(min, 9999);
    ctrl.text = next.toString();
    ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
  }

  Widget _buildNumBox({
    required String label,
    required String unit,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int minVal,
    required bool isOptional,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        border: Border.all(color: const Color(0xFFE0D9F5), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        // Label on top
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9B8DB8))),
        ),

        // DIRECT TEXT INPUT — main feature
        Container(
          color: Colors.white,
          child: TextField(
            controller: controller,
            focusNode: focusNode,

            // Numeric keyboard
            keyboardType:
                const TextInputType.numberWithOptions(signed: false, decimal: false),

            // Only digits allowed
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],

            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2540)),

            decoration: InputDecoration(
              hintText: isOptional ? '—' : '0',
              hintStyle: const TextStyle(fontSize: 16, color: Color(0xFFB0A0CC)),
              border: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color(0xFFE0D9F5), width: 0.5),
                  borderRadius: BorderRadius.zero),
              enabledBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color(0xFFE0D9F5), width: 0.5),
                  borderRadius: BorderRadius.zero),
              focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color(0xFF6C5CE7), width: 1),
                  borderRadius: BorderRadius.zero),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),

            // On done: close keyboard
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => focusNode.unfocus(),

            // Validate on change
            onChanged: (val) {
              if (val.isEmpty) return;
              final n = int.tryParse(val) ?? 0;
              if (n < minVal) {
                controller.text = minVal.toString();
                controller.selection = TextSelection.collapsed(
                    offset: controller.text.length);
              }
            },
          ),
        ),

        // +/- buttons row — for fine adjustment
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // MINUS button
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _stepValue(controller, -1, min: minVal),
                  child: Container(
                    color: const Color(0xFFEDE9F8),
                    height: 36,
                    child: const Center(
                      child: Text('−',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF6C5CE7),
                              height: 1)),
                    ),
                  ),
                ),
              ),

              // Thin divider between buttons
              Container(width: 0.5, color: const Color(0xFFE0D9F5)),

              // PLUS button
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _stepValue(controller, 1, min: minVal),
                  child: Container(
                    color: const Color(0xFF6C5CE7),
                    height: 36,
                    child: const Center(
                      child: Text('+',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Unit label at bottom
        Padding(
          padding: const EdgeInsets.only(top: 3, bottom: 5),
          child: Text(unit,
              style: const TextStyle(fontSize: 9, color: Color(0xFFB0A0CC))),
        ),
      ]),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title,
      {required Color color, required Color bgColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}
