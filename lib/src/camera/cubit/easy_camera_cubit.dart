import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../easy_camera_config.dart';
import '../easy_camera_result.dart';
import '../easy_camera_settings.dart';
import 'easy_camera_state.dart';

/// Cubit for managing camera state.
class EasyCameraCubit extends Cubit<EasyCameraState> {
  final EasyCameraConfig config;
  final EasyCameraSettings? initialSettings;

  EasyCameraCubit(
    this.config, {
    this.initialSettings,
  }) : super(
          initialSettings != null
              ? EasyCameraReady.fromSettings(initialSettings)
              : EasyCameraReady(
                  currentCamera: config.initialCamera,
                  flashMode: config.initialFlashMode,
                  zoomLevel: config.initialZoom,
                  imageQuality: config.imageQuality,
                ),
        );

  /// Called when camera switch is triggered.
  void onCameraSwitched(SensorPosition position, {bool? zoomSupported}) {
    if (state is EasyCameraReady) {
      emit((state as EasyCameraReady).copyWith(
        currentCamera: position,
        zoomSupported: zoomSupported,
      ));
    }
  }

  /// Updates zoom support status for current camera.
  void setZoomSupported(bool supported) {
    if (state is EasyCameraReady) {
      emit((state as EasyCameraReady).copyWith(zoomSupported: supported));
    }
  }

  /// Called when flash mode is changed.
  void onFlashModeChanged(FlashMode mode) {
    if (state is EasyCameraReady) {
      emit((state as EasyCameraReady).copyWith(flashMode: mode));
    }
  }

  /// Called when zoom level is changed.
  void onZoomChanged(double zoom) {
    if (state is EasyCameraReady) {
      emit((state as EasyCameraReady).copyWith(zoomLevel: zoom.clamp(0.0, 1.0)));
    }
  }

  /// Called when image quality is changed.
  void onImageQualityChanged(double quality) {
    if (state is EasyCameraReady) {
      emit((state as EasyCameraReady).copyWith(imageQuality: quality.clamp(0.0, 1.0)));
    }
  }

  /// Returns current settings for persistence.
  EasyCameraSettings? getCurrentSettings() {
    if (state is EasyCameraReady) {
      return (state as EasyCameraReady).toSettings();
    }
    return null;
  }

  /// Called when capture starts.
  void onCaptureStart() {
    emit(const EasyCameraCapturing());
  }

  /// Called when capture is successful.
  void onCaptureSuccess(String filePath) {
    emit(EasyCameraCaptured(EasyCameraResult(filePath: filePath)));
  }

  /// Called when capture fails.
  void onCaptureError(Object error) {
    emit(EasyCameraError('Failed to capture photo', error));
  }

  /// Called when camera permission is denied.
  void onPermissionDenied() {
    emit(const EasyCameraPermissionDenied());
  }

  /// Called when a general error occurs.
  void setError(String message, [Object? error]) {
    emit(EasyCameraError(message, error));
  }

  /// Resets state to ready with initial or saved settings.
  void reset() {
    if (initialSettings != null) {
      emit(EasyCameraReady.fromSettings(initialSettings!));
    } else {
      emit(EasyCameraReady(
        currentCamera: config.initialCamera,
        flashMode: config.initialFlashMode,
        zoomLevel: config.initialZoom,
        imageQuality: config.imageQuality,
      ));
    }
  }
}
