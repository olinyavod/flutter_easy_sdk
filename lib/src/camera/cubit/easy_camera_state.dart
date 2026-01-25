import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:equatable/equatable.dart';

import '../easy_camera_result.dart';
import '../easy_camera_settings.dart';

/// Base class for camera states.
sealed class EasyCameraState extends Equatable {
  const EasyCameraState();

  @override
  List<Object?> get props => [];
}

/// Initial state before camera is initialized.
class EasyCameraInitial extends EasyCameraState {
  const EasyCameraInitial();
}

/// Camera is ready for capture.
class EasyCameraReady extends EasyCameraState {
  final SensorPosition currentCamera;
  final FlashMode flashMode;
  final double zoomLevel;
  final double imageQuality;
  final bool zoomSupported;

  const EasyCameraReady({
    required this.currentCamera,
    required this.flashMode,
    this.zoomLevel = 0.0,
    this.imageQuality = 0.85,
    this.zoomSupported = true,
  });

  /// Converts current state to settings for persistence.
  EasyCameraSettings toSettings() {
    return EasyCameraSettings(
      flashMode: flashMode,
      cameraPosition: currentCamera,
      zoomLevel: zoomLevel,
      imageQuality: imageQuality,
    );
  }

  /// Creates state from saved settings.
  factory EasyCameraReady.fromSettings(EasyCameraSettings settings) {
    return EasyCameraReady(
      currentCamera: settings.cameraPosition,
      flashMode: settings.flashMode,
      zoomLevel: settings.zoomLevel,
      imageQuality: settings.imageQuality,
    );
  }

  @override
  List<Object?> get props => [currentCamera, flashMode, zoomLevel, imageQuality, zoomSupported];

  EasyCameraReady copyWith({
    SensorPosition? currentCamera,
    FlashMode? flashMode,
    double? zoomLevel,
    double? imageQuality,
    bool? zoomSupported,
  }) {
    return EasyCameraReady(
      currentCamera: currentCamera ?? this.currentCamera,
      flashMode: flashMode ?? this.flashMode,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      imageQuality: imageQuality ?? this.imageQuality,
      zoomSupported: zoomSupported ?? this.zoomSupported,
    );
  }
}

/// Camera is capturing a photo.
class EasyCameraCapturing extends EasyCameraState {
  const EasyCameraCapturing();
}

/// Photo was captured successfully.
class EasyCameraCaptured extends EasyCameraState {
  final EasyCameraResult result;

  const EasyCameraCaptured(this.result);

  @override
  List<Object?> get props => [result];
}

/// Camera permission was denied.
class EasyCameraPermissionDenied extends EasyCameraState {
  const EasyCameraPermissionDenied();
}

/// Camera error occurred.
class EasyCameraError extends EasyCameraState {
  final String message;
  final Object? error;

  const EasyCameraError(this.message, [this.error]);

  @override
  List<Object?> get props => [message, error];
}
