import 'package:equatable/equatable.dart';

/// Base class for image viewer states.
sealed class EasyImageViewerState extends Equatable {
  const EasyImageViewerState();

  @override
  List<Object?> get props => [];
}

/// Image viewer is ready.
class EasyImageViewerReady extends EasyImageViewerState {
  /// Current zoom scale.
  final double scale;

  /// Current horizontal offset.
  final double offsetX;

  /// Current vertical offset.
  final double offsetY;

  /// Whether controls are visible.
  final bool controlsVisible;

  /// Image dimensions (if loaded).
  final int? imageWidth;

  /// Image dimensions (if loaded).
  final int? imageHeight;

  const EasyImageViewerReady({
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.controlsVisible = true,
    this.imageWidth,
    this.imageHeight,
  });

  @override
  List<Object?> get props => [
        scale,
        offsetX,
        offsetY,
        controlsVisible,
        imageWidth,
        imageHeight,
      ];

  EasyImageViewerReady copyWith({
    double? scale,
    double? offsetX,
    double? offsetY,
    bool? controlsVisible,
    int? imageWidth,
    int? imageHeight,
  }) {
    return EasyImageViewerReady(
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      controlsVisible: controlsVisible ?? this.controlsVisible,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }
}

/// Image is loading.
class EasyImageViewerLoading extends EasyImageViewerState {
  const EasyImageViewerLoading();
}

/// Image loading failed.
class EasyImageViewerError extends EasyImageViewerState {
  final String message;
  final Object? error;

  const EasyImageViewerError(this.message, [this.error]);

  @override
  List<Object?> get props => [message, error];
}
