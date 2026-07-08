import 'package:flutter/material.dart';

class FolderColor {
  final String name;
  final Color mainColor;
  final Color lightBg;
  final Color darkIcon;

  const FolderColor({
    required this.name,
    required this.mainColor,
    required this.lightBg,
    required this.darkIcon,
  });
}

// Color Palette Definitions
final List<FolderColor> warmColors = [
  const FolderColor(name: 'Red', mainColor: Color(0xFFE53935), lightBg: Color(0xFFFFEBEE), darkIcon: Color(0xFFC62828)),
  const FolderColor(name: 'Orange', mainColor: Color(0xFFFB8C00), lightBg: Color(0xFFFFF3E0), darkIcon: Color(0xFFE65100)),
  const FolderColor(name: 'Yellow', mainColor: Color(0xFFFDD835), lightBg: Color(0xFFFFFDE7), darkIcon: Color(0xFFF57F17)),
  const FolderColor(name: 'Pink', mainColor: Color(0xFFF06292), lightBg: Color(0xFFFCE4EC), darkIcon: Color(0xFFAD1457)),
  const FolderColor(name: 'Deep Orange', mainColor: Color(0xFFFF7043), lightBg: Color(0xFFFBE9E7), darkIcon: Color(0xFFBF360C)),
];

final List<FolderColor> coolColors = [
  const FolderColor(name: 'Blue', mainColor: Color(0xFF1E88E5), lightBg: Color(0xFFE3F2FD), darkIcon: Color(0xFF1565C0)),
  const FolderColor(name: 'Cyan', mainColor: Color(0xFF00ACC1), lightBg: Color(0xFFE0F7FA), darkIcon: Color(0xFF00838F)),
  const FolderColor(name: 'Green', mainColor: Color(0xFF43A047), lightBg: Color(0xFFE8F5E9), darkIcon: Color(0xFF2E7D32)),
  const FolderColor(name: 'Teal', mainColor: Color(0xFF26A69A), lightBg: Color(0xFFE0F2F1), darkIcon: Color(0xFF00695C)),
  const FolderColor(name: 'Indigo', mainColor: Color(0xFF5C6BC0), lightBg: Color(0xFFE8EAF6), darkIcon: Color(0xFF283593)),
];

final FolderColor purpleDefault = const FolderColor(
  name: 'Purple', 
  mainColor: Color(0xFF6C5CE7), 
  lightBg: Color(0xFFEDE9F8), 
  darkIcon: Color(0xFF6C5CE7)
);

final List<FolderColor> neutralColors = [
  purpleDefault,
  const FolderColor(name: 'Violet', mainColor: Color(0xFF8E24AA), lightBg: Color(0xFFF3E5F5), darkIcon: Color(0xFF6A1B9A)),
  const FolderColor(name: 'Gray', mainColor: Color(0xFF78909C), lightBg: Color(0xFFECEFF1), darkIcon: Color(0xFF37474F)),
  const FolderColor(name: 'Brown', mainColor: Color(0xFF6D4C41), lightBg: Color(0xFFEFEBE9), darkIcon: Color(0xFF4E342E)),
  const FolderColor(name: 'Blue Gray', mainColor: Color(0xFF546E7A), lightBg: Color(0xFFECEFF1), darkIcon: Color(0xFF263238)),
];

Future<Map<String, dynamic>?> showCreateFolderDialog(
  BuildContext context, {
  String? initialName,
  int? initialColorValue,
  int? initialLightBgColorValue,
  int? initialDarkIconColorValue,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: const Color(0xFFFAFAFF),
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => CreateFolderDialog(
      initialName: initialName,
      initialColorValue: initialColorValue,
      initialLightBgColorValue: initialLightBgColorValue,
      initialDarkIconColorValue: initialDarkIconColorValue,
    ),
  );
}

class CreateFolderDialog extends StatefulWidget {
  final String? initialName;
  final int? initialColorValue;
  final int? initialLightBgColorValue;
  final int? initialDarkIconColorValue;

  const CreateFolderDialog({
    super.key,
    this.initialName,
    this.initialColorValue,
    this.initialLightBgColorValue,
    this.initialDarkIconColorValue,
  });

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  late TextEditingController _controller;
  String folderName = '';
  late FolderColor selectedColor;

  @override
  void initState() {
    super.initState();
    folderName = widget.initialName ?? '';
    _controller = TextEditingController(text: folderName);

    // Try to find the initial color in our palette
    if (widget.initialColorValue != null) {
      final allColors = [...warmColors, ...coolColors, ...neutralColors];
      selectedColor = allColors.firstWhere(
        (c) => c.mainColor.value == widget.initialColorValue,
        orElse: () => FolderColor(
          name: 'Custom',
          mainColor: Color(widget.initialColorValue!),
          lightBg: Color(widget.initialLightBgColorValue ?? Color(0xFFEDE9F8).value),
          darkIcon: Color(widget.initialDarkIconColorValue ?? widget.initialColorValue!),
        ),
      );
    } else {
      selectedColor = purpleDefault;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get canCreate => folderName.trim().isNotEmpty;

  void selectColor(FolderColor color) {
    setState(() {
      selectedColor = color;
    });
  }

  void resetToDefault() => selectColor(purpleDefault);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create new folder",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D2540),
                ),
              ),
              const SizedBox(height: 14),
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: (val) {
                      setState(() {
                        folderName = val;
                      });
                    },
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2D2540)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(48, 10, 12, 10),
                      fillColor: const Color(0xFFF5F0FF),
                      filled: true,
                      hintText: "Folder ka naam likhein...",
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0A0CC)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD8D0F0), width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD8D0F0), width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.0),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: selectedColor.lightBg,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        Icons.folder,
                        size: 16,
                        color: selectedColor.darkIcon,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 2),
                child: Text(
                  "Naam dikhaye ga folder card mein",
                  style: TextStyle(fontSize: 10, color: Color(0xFF9B8DB8)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "COLOR CHUNEIN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9B8DB8),
                      letterSpacing: 0.04,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: selectedColor.mainColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              selectedColor.name,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6C5CE7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: resetToDefault,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9F8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.refresh, size: 11, color: Color(0xFF6C5CE7)),
                              SizedBox(width: 4),
                              Text(
                                "Default",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6C5CE7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildColorGroup("Warm", warmColors),
              const SizedBox(height: 10),
              _buildColorGroup("Cool", coolColors),
              const SizedBox(height: 10),
              _buildColorGroup("Neutral", neutralColors),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EBF8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: canCreate ? () {
                        Navigator.pop(context, {
                          'name': folderName,
                          'colorValue': selectedColor.mainColor.value,
                          'lightBgColorValue': selectedColor.lightBg.value,
                          'darkIconColorValue': selectedColor.darkIcon.value,
                        });
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: canCreate ? const Color(0xFF6C5CE7) : const Color(0xFFD8D0F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.create_new_folder_outlined, size: 15, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "Create folder",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorGroup(String label, List<FolderColor> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFB0A0CC),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: colors.map((color) => _buildColorSwatch(color)).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSwatch(FolderColor folderColor) {
    final bool isSelected = selectedColor.mainColor.value == folderColor.mainColor.value;
    
    return GestureDetector(
      onTap: () => selectColor(folderColor),
      child: Container(
        width: 32,
        height: 32,
        decoration: isSelected ? BoxDecoration(
          border: Border.all(color: const Color(0xFF6C5CE7), width: 2.5),
          borderRadius: BorderRadius.circular(16),
        ) : null,
        padding: isSelected ? const EdgeInsets.all(1) : EdgeInsets.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: folderColor.mainColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
      ),
    );
  }
}
