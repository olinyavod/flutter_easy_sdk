import 'package:flutter_bloc/flutter_bloc.dart';

import '../easy_image_viewer_config.dart';
import 'easy_image_viewer_state.dart';

/// Cubit for managing image viewer state.
class EasyImageViewerCubit extends Cubit<EasyImageViewerState> {
  final EasyImageViewerConfig config;

  EasyImageViewerCubit(this.config) : super(const EasyImageViewerReady(scale: 1.0));

  /// Marks image loading as started.
  void startLoading() {
    emit(const EasyImageViewerLoading());
  }

  /// Called when image is successfully loaded.
  void onImageLoadSuccess() {
    emit(EasyImageViewerReady(scale: config.initialScale));
  }

  /// Updates the zoom scale.
  void onScaleChanged(double scale) {
    if (state is EasyImageViewerReady) {
      final clampedScale = scale.clamp(config.minScale, config.maxScale);
      emit((state as EasyImageViewerReady).copyWith(scale: clampedScale));
    }
  }

  /// Updates the pan offset.
  void onOffsetChanged(double offsetX, double offsetY) {
    if (state is EasyImageViewerReady) {
      emit((state as EasyImageViewerReady).copyWith(
        offsetX: offsetX,
        offsetY: offsetY,
      ));
    }
  }

  /// Toggles controls visibility.
  void toggleControls() {
    if (state is EasyImageViewerReady) {
      final current = state as EasyImageViewerReady;
      emit(current.copyWith(controlsVisible: !current.controlsVisible));
    }
  }

  /// Shows controls.
  void showControls() {
    if (state is EasyImageViewerReady) {
      emit((state as EasyImageViewerReady).copyWith(controlsVisible: true));
    }
  }

  /// Hides controls.
  void hideControls() {
    if (state is EasyImageViewerReady) {
      emit((state as EasyImageViewerReady).copyWith(controlsVisible: false));
    }
  }

  /// Sets image dimensions when loaded.
  void onImageLoaded(int width, int height) {
    if (state is EasyImageViewerReady) {
      emit((state as EasyImageViewerReady).copyWith(
        imageWidth: width,
        imageHeight: height,
      ));
    }
  }

  /// Resets zoom and position to initial state.
  void reset() {
    emit(EasyImageViewerReady(scale: config.initialScale));
  }

  /// Sets an error state.
  void setError(String message, [Object? error]) {
    emit(EasyImageViewerError(message, error));
  }

  /// Retries loading the image.
  void retry() {
    emit(const EasyImageViewerLoading());
  }

  /// Double-tap zoom toggle.
  void onDoubleTap() {
    if (!config.doubleTapToZoom) return;
    if (state is EasyImageViewerReady) {
      final current = state as EasyImageViewerReady;
      // Toggle between initial scale and 2x zoom
      final targetScale = current.scale > config.initialScale
          ? config.initialScale
          : (config.initialScale * 2).clamp(config.minScale, config.maxScale);
      emit(current.copyWith(
        scale: targetScale,
        offsetX: 0.0,
        offsetY: 0.0,
      ));
    }
  }
}
