import 'package:equatable/equatable.dart';
import 'package:notepad_pro/domain/entities/folder.dart';

abstract class FoldersState extends Equatable {
  const FoldersState();

  @override
  List<Object?> get props => [];
}

class FoldersInitial extends FoldersState {}

class FoldersLoadInProgress extends FoldersState {}

class FoldersLoadSuccess extends FoldersState {
  final List<Folder> folders;

  const FoldersLoadSuccess(this.folders);

  @override
  List<Object?> get props => [folders];
}

class FoldersLoadFailure extends FoldersState {
  final String message;

  const FoldersLoadFailure(this.message);

  @override
  List<Object?> get props => [message];
}
