import 'package:flutter_bloc/flutter_bloc.dart';

class SelectionState {
  final Map<String, bool> selectedMap; // id -> isFolder flag
  const SelectionState({required this.selectedMap});

  bool get isSelectionMode => selectedMap.isNotEmpty;
  int get selectedCount => selectedMap.length;
  bool get isSelecting => isSelectionMode;
  Set<String> get selectedIds => selectedMap.keys.toSet();
}

class SelectionCubit extends Cubit<SelectionState> {
  SelectionCubit() : super(const SelectionState(selectedMap: <String, bool>{}));

  void toggleSelection(String id, bool isFolder) {
    final newMap = Map<String, bool>.from(state.selectedMap);
    if (newMap.containsKey(id)) {
      newMap.remove(id);
    } else {
      newMap[id] = isFolder;
    }
    if (newMap.isEmpty) {
      clearSelection();
    } else {
      emit(SelectionState(selectedMap: newMap));
    }
  }

  void clearSelection() {
    emit(const SelectionState(selectedMap: <String, bool>{}));
  }

  void selectAll(List<dynamic> folders, List<dynamic> files) {
    final newMap = Map<String, bool>.from(state.selectedMap);
    for (final folder in folders) {
      newMap[folder.id] = true;
    }
    for (final file in files) {
      newMap[file.id] = false;
    }
    if (newMap.isEmpty) {
      clearSelection();
    } else {
      emit(SelectionState(selectedMap: newMap));
    }
  }

  void keepOnly(List<String> visibleIds) {
    final newMap = Map<String, bool>.from(state.selectedMap);
    final initialLength = newMap.length;
    newMap.removeWhere((id, _) => !visibleIds.contains(id));
    if (newMap.length != initialLength) {
      if (newMap.isEmpty) {
        clearSelection();
      } else {
        emit(SelectionState(selectedMap: newMap));
      }
    }
  }
}
