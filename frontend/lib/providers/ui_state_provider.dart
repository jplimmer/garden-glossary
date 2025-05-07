import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data class for UI state
class UIState {
  final bool isSubmitted;
  final bool isImageMoved;
  final bool isIDBoxExpanded;
  final bool isTextStreaming;

  const UIState({
    this.isSubmitted = false,
    this.isImageMoved = false,
    this.isIDBoxExpanded = false,
    this.isTextStreaming = false,
  });

  UIState copyWith({
    bool? isSubmitted,
    bool? isImageMoved,
    bool? isIDBoxExpanded,
    bool? isTextStreaming,
  }) {
    return UIState(
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isImageMoved: isImageMoved ?? this.isImageMoved,
      isIDBoxExpanded: isIDBoxExpanded ?? this.isIDBoxExpanded,
      isTextStreaming: isTextStreaming ?? this.isTextStreaming,
    );
  }
}

/// StateNotifier for UI state
class UIStateNotifier extends StateNotifier<UIState> {
  UIStateNotifier() : super(const UIState());
  
  /// Update submission state
  void setIsSubmitted(bool submitted) {
    state = state.copyWith(isSubmitted: submitted);
  }
  
  /// Update image animation state
  void setImageMoved(bool moved) {
    state = state.copyWith(isImageMoved: moved);
  }

  /// Update IDBox expansion state
  void setIDBoxExpanded(bool expanded) {
    state = state.copyWith(isIDBoxExpanded: expanded);
  }
  
  /// Toggle IDBox expansion state
  void toggleIDBoxExpanded() {
    state = state.copyWith(isIDBoxExpanded: !state.isIDBoxExpanded);
  }

  /// Start text streaming
  void startTextStreaming() {
    state = state.copyWith(isTextStreaming: true);
  }

  /// Stop text streaming
  void stopTextStreaming() {
    state = state.copyWith(isTextStreaming: false);
  }

  /// Toggle text streaming
  void toggleTextStreaming() {
    state = state.copyWith(isTextStreaming: !state.isTextStreaming);
  }

  /// Reset UI state
  void reset() {
    state = const UIState();
  }
}

/// Provider for tracking UI animation states
final uiStateProvider = StateNotifierProvider<UIStateNotifier, UIState>((ref) {
  return UIStateNotifier();
});

