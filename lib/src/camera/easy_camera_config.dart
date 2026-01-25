import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

/// Configuration for camera page appearance and behavior.
class EasyCameraConfig {
  /// Background color for controls overlay.
  final Color? backgroundColor;

  /// Icon color for control buttons.
  final Color? iconColor;

  /// Capture button color.
  final Color? captureButtonColor;

  /// Whether to show camera switch button.
  final bool showSwitchCamera;

  /// Whether to show flash toggle button.
  final bool showFlashButton;

  /// Initial camera position.
  final SensorPosition initialCamera;

  /// Image quality (0.0 - 1.0).
  final double imageQuality;

  /// Maximum image width in pixels.
  final int? maxWidth;

  /// Maximum image height in pixels.
  final int? maxHeight;

  /// Custom title for the camera page.
  final String? title;

  /// Custom back button text.
  final String? backButtonText;

  /// Initial flash mode.
  final FlashMode initialFlashMode;

  /// Initial zoom level (0.0 - 1.0).
  final double initialZoom;

  /// Whether to show zoom slider.
  final bool showZoomSlider;

  const EasyCameraConfig({
    this.backgroundColor,
    this.iconColor,
    this.captureButtonColor,
    this.showSwitchCamera = true,
    this.showFlashButton = true,
    this.initialCamera = SensorPosition.back,
    this.imageQuality = 0.85,
    this.maxWidth,
    this.maxHeight,
    this.title,
    this.backButtonText,
    this.initialFlashMode = FlashMode.auto,
    this.initialZoom = 0.0,
    this.showZoomSlider = true,
  });

  /// Creates a configuration from the app theme.
  factory EasyCameraConfig.fromTheme(ThemeData theme) {
    return EasyCameraConfig(
      backgroundColor: theme.colorScheme.surface.withAlpha(200),
      iconColor: theme.colorScheme.onSurface,
      captureButtonColor: theme.colorScheme.primary,
    );
  }

  /// Creates a copy with updated values.
  EasyCameraConfig copyWith({
    Color? backgroundColor,
    Color? iconColor,
    Color? captureButtonColor,
    bool? showSwitchCamera,
    bool? showFlashButton,
    SensorPosition? initialCamera,
    double? imageQuality,
    int? maxWidth,
    int? maxHeight,
    String? title,
    String? backButtonText,
    FlashMode? initialFlashMode,
    double? initialZoom,
    bool? showZoomSlider,
  }) {
    return EasyCameraConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconColor: iconColor ?? this.iconColor,
      captureButtonColor: captureButtonColor ?? this.captureButtonColor,
      showSwitchCamera: showSwitchCamera ?? this.showSwitchCamera,
      showFlashButton: showFlashButton ?? this.showFlashButton,
      initialCamera: initialCamera ?? this.initialCamera,
      imageQuality: imageQuality ?? this.imageQuality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      title: title ?? this.title,
      backButtonText: backButtonText ?? this.backButtonText,
      initialFlashMode: initialFlashMode ?? this.initialFlashMode,
      initialZoom: initialZoom ?? this.initialZoom,
      showZoomSlider: showZoomSlider ?? this.showZoomSlider,
    );
  }
}
