import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aula360/core/service/language/language_provider.dart';
import '../../data/dtos/child_progress_dto.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../domain/repositories/parent_repository.dart';

class ParentProgressState {
  final Map<String, ChildProgressDto> progressByChild;
  final bool isLoading;
  final String? error;

  const ParentProgressState({
    this.progressByChild = const {},
    this.isLoading = false,
    this.error,
  });

  ParentProgressState copyWith({
    Map<String, ChildProgressDto>? progressByChild,
    bool? isLoading,
    String? error,
  }) {
    return ParentProgressState(
      progressByChild: progressByChild ?? this.progressByChild,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final parentProgressControllerProvider =
    NotifierProvider<ParentProgressController, ParentProgressState>(
  ParentProgressController.new,
);

class ParentProgressController extends Notifier<ParentProgressState> {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  ParentProgressState build() {
    ref.listen<AsyncValue<LanguageState>>(languageProvider, (previous, next) {
      final prevCode = previous?.asData?.value.languageCode;
      final nextCode = next.asData?.value.languageCode;
      if (prevCode != null && nextCode != null && prevCode != nextCode) {
        final childIds = state.progressByChild.keys.toList();
        state = state.copyWith(progressByChild: const {});
        for (final id in childIds) {
          Future.microtask(() => loadProgress(id));
        }
      }
    });
    return const ParentProgressState();
  }

  Future<ChildProgressDto?> loadProgress(String childId) async {
    if (childId.isEmpty) return null;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final progress = await _repository.getChildProgress(childId);
      final updated = Map<String, ChildProgressDto>.from(state.progressByChild);
      updated[childId] = progress;
      state = state.copyWith(
        progressByChild: updated,
        isLoading: false,
        error: null,
      );
      return progress;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  ChildProgressDto? getProgressForChild(String childId) {
    return state.progressByChild[childId];
  }
}
