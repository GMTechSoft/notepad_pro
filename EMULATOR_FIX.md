# Emulator Recovery and Crash Prevention Guide

## 1. Recovery Steps for MEmu Play (Stuck at 59%)

To clear dangling processes and stale locks that prevent MEmu from booting, run these commands in a **PowerShell** window as Administrator:

### A. Kill Dangling Processes
```powershell
# Kill ADB and all MEmu related processes
taskkill /F /IM "MEmu.exe" /T
taskkill /F /IM "MEmuHeadless.exe" /T
taskkill /F /IM "MEmuConsole.exe" /T
taskkill /F /IM "adb.exe" /T
```

### B. Wipe Stale Locks and Temp Cache
MEmu often gets stuck if `.lock` files or temporary state files are left behind.
1. Navigate to your MEmu installation folder (usually `C:\Program Files\Microvirt\MEmu` or wherever your VMs are stored, e.g., `C:\Users\<YourUser>\AppData\Local\MEmu`).
2. Search for and delete any files ending in `.lock`.
3. Clear the MEmu temp directory:
   ```powershell
   Remove-Item -Path "$env:LOCALAPPDATA\MEmu\MemuHyperv\*.log" -ErrorAction SilentlyContinue
   ```

### C. Repair MEmu (Manual Step)
1. Open **Multi-MEmu** (MEmu Console).
2. Click the **Settings (Gear icon)** for the specific VM.
3. Go to **Engine** -> **Repair** (if available) or simply change the **Render Mode** (see below) to force a config refresh.

---

## 2. Prevention: Flutter & Hardware Graphics Stability

The color picker crash is likely caused by a conflict between the emulator's hardware-accelerated GL layer and Flutter's Skia/Impeller rendering when handling complex dialog overlays.

### A. Change Emulator Render Mode (Recommended)
Switch MEmu's rendering engine to **DirectX** instead of OpenGL. OpenGL in emulators is often less stable with complex Flutter UI transitions.
1. Open **Multi-MEmu**.
2. Settings -> **Engine**.
3. Set **Render Mode** to **DirectX**.
4. Set **GPU Memory Optimization** to **Off** if it's on.

### B. Disable Hardware Acceleration in Flutter (Debug Only)
If the crash persists, you can force Flutter to use the software backend for debugging, which bypasses the emulator's flaky driver layer:
```bash
flutter run --no-enable-impeller --enable-software-rendering
```

### C. Optimize Color Picker Dialog Performance
In your Flutter code, ensure the dialog isn't causing excessive repaints. You can wrap the color picker in a `RepaintBoundary` to isolate its rendering layer:

```dart
// Example modification in create_folder_dialog.dart
RepaintBoundary(
  child: ColorPicker(
    pickerColor: tempColor,
    onColorChanged: (color) => tempColor = color,
    // ... other properties
  ),
)
```

### D. System Level Check
Ensure your host PC's graphics drivers are up to date and that **VT-x/AMD-V** (Virtualization Technology) is enabled in your BIOS/UEFI. Emulators often fail during heavy UI tasks if virtualization is not fully utilized.
