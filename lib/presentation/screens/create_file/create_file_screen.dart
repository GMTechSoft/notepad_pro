import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notepad_pro/presentation/blocs/sync/sync_cubit.dart';
import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import 'package:notepad_pro/domain/entities/vault_file.dart';
import 'package:notepad_pro/presentation/blocs/files/files_cubit.dart';
import 'package:notepad_pro/core/theme/theme_extensions.dart';

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
  bool _isSaving = false; // guard against concurrent saves
  late final String _stableFileId; // stable ID for this session
  late final AppLifecycleListener _lifecycleListener; // listener for app lifecycle events

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

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

  /// Unified save method used by both auto‑save and manual save actions.
  Future<void> _performSecureSaveAndSync({required bool isManualSave}) async {
    final saveSource = isManualSave ? 'MANUAL' : 'AUTO/LIFECYCLE';
    debugPrint('SAVE_START - source: $saveSource, title: "${_titleController.text}", descLen: ${_descriptionController.text.length}');
    
    // Do nothing if both title and description are empty.
    if (_titleController.text.trim().isEmpty && _descriptionController.text.trim().isEmpty) {
      debugPrint('SAVE_ABORT - Both empty');
      return;
    }

    // Wait for any ongoing save to finish before starting a new one (flush pending saves)
    while (_isSaving) {
      debugPrint('SAVE_WAITING - Waiting for ongoing save to finish...');
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (!mounted) {
      debugPrint('SAVE_ABORT - Not mounted');
      return;
    }
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
      lineNumber: _addReference && _referenceType == ReferenceType.book ? int.tryParse(_lineCtrl.text) : null,
    );

    debugPrint('SAVE_EXECUTE - id: ${finalFile.id}, title: "${finalFile.title}", descLen: ${finalFile.description.length}');

    try {
      if (widget.initialFile == null && !_hasCreatedAuto) {
        // New file – use createFile to insert into local DB.
        await context.read<FilesCubit>().createFile(
          id: finalFile.id,
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
        debugPrint('SAVE_SUCCESS - Created new file');
      } else {
        // Existing or already created file – update.
        await context.read<FilesCubit>().updateFile(finalFile);
        debugPrint('SAVE_SUCCESS - Updated existing file');
      }

      // If auto‑sync is enabled and this is a manual save, trigger a single file upload to Google Drive.
      final configBox = Hive.box('settings');
      final bool isAutoSyncEnabled = (configBox.get('auto_sync', defaultValue: false) as bool);
      if (isAutoSyncEnabled && mounted) {
        await context.read<SyncCubit>().syncNow();
      }
    } catch (error) {
      // Log any error – keep UI responsive.
      debugPrint('Database or Cloud pipeline handling error: $error');
    } finally {
      // Reset saving guard.
      _isSaving = false;
      debugPrint('SAVE_DONE - Finished');
      // If this was an explicit manual save, navigate back.
      if (isManualSave && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  bool _canPop = false; // Add variable for PopScope

  @override
  void dispose() {
    // Dispose lifecycle listener
    _lifecycleListener.dispose();

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, dynamic result) async {
        if (didPop) return;
        await _performSecureSaveAndSync(isManualSave: false);
        if (mounted) {
          setState(() {
            _canPop = true;
          });
          Navigator.of(this.context).pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
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
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.border, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: TextFormField(
                  controller: _titleController,
                  cursorColor: context.primaryColor,
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
                  decoration: InputDecoration(
                    hintText: 'Enter file name...',
                    hintStyle: TextStyle(color: context.subText, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 13, color: context.primaryText),
                ),
              ),
              const SizedBox(height: 10),
              _buildFieldLabel("Description"),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.border, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: TextFormField(
                  controller: _descriptionController,
                  cursorColor: context.primaryColor,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textDirection: _isUrdu(_descriptionController.text) ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: _isUrdu(_descriptionController.text) ? TextAlign.right : TextAlign.left,
                  onChanged: (val) => setState(() {}),
                  validator: (val) => null,
                  decoration: InputDecoration(
                    hintText: "Write your notes here...",
                    hintStyle: TextStyle(color: context.subText, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 13, color: context.primaryText),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: context.border, thickness: 0.5),
              const SizedBox(height: 16),

              // Reference Toggle Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Add reference",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: context.primaryText,
                            ),
                          ),
                          Text(
                            "Link book or video (optional)",
                            style: TextStyle(fontSize: 10, color: context.subText),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _addReference,
                      onChanged: (val) => setState(() => _addReference = val),
                      activeThumbColor: context.isDark ? Colors.black : Colors.white,
                      activeTrackColor: context.primaryColor,
                    ),
                  ],
                ),
              ),

              if (_addReference) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: context.border, width: 0.5),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: context.highlightBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: context.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _referenceType == ReferenceType.video
                              ? "Jump directly to that time using timestamp"
                              : "References will appear in search after saving",
                          style: TextStyle(
                            fontSize: 11, 
                            color: context.isDark ? const Color(0xFFBBADFF) : const Color(0xFF534AB7),
                          ),
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final bool isSaveDisabled = _titleController.text.trim().isEmpty;

    return AppBar(
      backgroundColor: context.scaffoldBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          _buildCircleButton(
            icon: Icons.arrow_back,
            onPressed: () async {
              await _performSecureSaveAndSync(isManualSave: false);
              if (mounted) context.pop();
            },
          ),
          const Spacer(),
          Text(
            "Create new file",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.primaryText,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: (isSaveDisabled || _isSaving) ? null : () async => await _performSecureSaveAndSync(isManualSave: true),
            icon: _isSaving
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, 
                      valueColor: AlwaysStoppedAnimation(context.isDark ? Colors.black : Colors.white),
                    ),
                  )
                : Icon(Icons.save, size: 14, color: context.isDark ? Colors.black : Colors.white),
            label: Text("Save",
                style: TextStyle(color: context.isDark ? Colors.black : Colors.white, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              disabledBackgroundColor: context.isDark ? Colors.grey.shade800 : Colors.grey.shade400,
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

  Widget _buildCircleButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: context.highlightBg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: context.primaryColor),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: context.subText,
          fontWeight: FontWeight.w500,
        ),
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: TextFormField(
        initialValue: initialValue,
        onSaved: onSaved,
        onChanged: onChanged,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        cursorColor: context.primaryColor,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.subText, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
        ),
        style: TextStyle(fontSize: 13, color: context.primaryText),
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
            color: isActive ? context.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isActive ? (context.isDark ? Colors.black : Colors.white) : context.subText,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? (context.isDark ? Colors.black : Colors.white) : context.subText,
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
            color: context.primaryColor, bgColor: context.highlightBg),
        _buildFieldLabel("Book Title *"),
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.border, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: TextFormField(
            controller: _bookTitleController,
            cursorColor: context.primaryColor,
            maxLines: null,
            minLines: 1,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            validator: (val) => (_addReference &&
                    _referenceType == ReferenceType.book &&
                    (val?.isEmpty ?? true))
                ? 'Required'
                : null,
            decoration: InputDecoration(
              hintText: 'e.g. Aab-e-Hayat',
              hintStyle: TextStyle(color: context.subText, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
            ),
            style: TextStyle(fontSize: 13, color: context.primaryText),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            Text("Volume / Page / Line",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.subText)),
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
        _buildFieldLabel("Author"),
        _buildTextField(
          hint: "e.g. Umera Ahmed",
          initialValue: _authorName,
          onSaved: (val) => _authorName = val ?? '',
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    final videoColor = context.isDark ? const Color(0xFFEF5350) : const Color(0xFFC0392B);
    final videoBg = context.isDark ? const Color(0xFF3C201E) : const Color(0xFFFDECEA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.play_circle_outline, "Video reference",
            color: videoColor, bgColor: videoBg),
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
        _buildFieldLabel("Timestamp — video time"),
        Row(children: [
          _tsBox("Hours", "hours", _hourCtrl, 99),
          const SizedBox(width: 6),
          _tsBox("Minutes", "min", _minCtrl, 59),
          const SizedBox(width: 6),
          _tsBox("Seconds", "sec", _secCtrl, 59),
        ]),
      ],
    );
  }

  Widget _tsBox(
      String label, String unit, TextEditingController controller, int max) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: context.highlightBg,
          border: Border.all(color: context.border, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(label,
                style: TextStyle(fontSize: 10, color: context.subText)),
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
                  decoration: BoxDecoration(
                    color: context.highlightBg,
                    borderRadius:
                        const BorderRadius.only(bottomLeft: Radius.circular(9)),
                  ),
                  child: Center(
                    child: Text("-",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: context.primaryColor)),
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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.primaryText),
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
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    borderRadius:
                        const BorderRadius.only(bottomRight: Radius.circular(9)),
                  ),
                  child: Center(
                    child: Text("+",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: context.isDark ? Colors.black : Colors.white)),
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
        color: context.highlightBg,
        border: Border.all(color: context.border, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        // Label on top
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(label,
              style: TextStyle(fontSize: 10, color: context.subText)),
        ),

        // DIRECT TEXT INPUT — main feature
        Container(
          color: context.cardBg,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            cursorColor: context.primaryColor,
            // Numeric keyboard
            keyboardType:
                const TextInputType.numberWithOptions(signed: false, decimal: false),

            // Only digits allowed
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],

            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.primaryText),

            decoration: InputDecoration(
              hintText: isOptional ? '—' : '0',
              hintStyle: TextStyle(fontSize: 16, color: context.subText),
              border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.border, width: 0.5),
                  borderRadius: BorderRadius.zero),
              enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.border, width: 0.5),
                  borderRadius: BorderRadius.zero),
              focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.primaryColor, width: 1),
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
                    color: context.highlightBg,
                    height: 36,
                    child: Center(
                      child: Text('−',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: context.primaryColor,
                              height: 1)),
                    ),
                  ),
                ),
              ),

              // Thin divider between buttons
              Container(width: 0.5, color: context.border),

              // PLUS button
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _stepValue(controller, 1, min: minVal),
                  child: Container(
                    color: context.primaryColor,
                    height: 36,
                    child: Center(
                      child: Text('+',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: context.isDark ? Colors.black : Colors.white,
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
              style: TextStyle(fontSize: 9, color: context.subText)),
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
