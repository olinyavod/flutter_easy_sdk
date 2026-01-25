import 'package:flutter/material.dart';

/// Configuration for EasyImageViewerPage.
class EasyImageViewerConfig {
  /// Background color of the viewer.
  final Color? backgroundColor;

  /// Icon color for action buttons.
  final Color? iconColor;

  /// Whether to show close button.
  final bool showCloseButton;

  /// Whether to show share button.
  final bool showShareButton;

  /// Whether to show delete button.
  final bool showDeleteButton;

  /// Whether to enable zoom gestures.
  final bool enableZoom;

  /// Minimum zoom scale.
  final double minScale;

  /// Maximum zoom scale.
  final double maxScale;

  /// Initial zoom scale.
  final double initialScale;

  /// Whether to enable double-tap to zoom.
  final bool doubleTapToZoom;

  /// Custom title for the viewer.
  final String? title;

  /// Custom close button tooltip.
  final String? closeTooltip;

  /// Custom share button tooltip.
  final String? shareTooltip;

  /// Custom delete button tooltip.
  final String? deleteTooltip;

  /// Whether to show image info (dimensions, size).
  final bool showImageInfo;

  /// Animation duration for zoom transitions.
  final Duration animationDuration;

  const EasyImageViewerConfig({
    this.backgroundColor,
    this.iconColor,
    this.showCloseButton = true,
    this.showShareButton = false,
    this.showDeleteButton = false,
    this.enableZoom = true,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.initialScale = 1.0,
    this.doubleTapToZoom = true,
    this.title,
    this.closeTooltip,
    this.shareTooltip,
    this.deleteTooltip,
    this.showImageInfo = false,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  /// Creates a configuration from the app theme.
  factory EasyImageViewerConfig.fromTheme(ThemeData theme) {
    return const EasyImageViewerConfig(
      backgroundColor: Colors.black,
      iconColor: Colors.white,
    );
  }

  /// Creates a copy with modified values.
  EasyImageViewerConfig copyWith({
    Color? backgroundColor,
    Color? iconColor,
    bool? showCloseButton,
    bool? showShareButton,
    bool? showDeleteButton,
    bool? enableZoom,
    double? minScale,
    double? maxScale,
    double? initialScale,
    bool? doubleTapToZoom,
    String? title,
    String? closeTooltip,
    String? shareTooltip,
    String? deleteTooltip,
    bool? showImageInfo,
    Duration? animationDuration,
  }) {
    return EasyImageViewerConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconColor: iconColor ?? this.iconColor,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      showShareButton: showShareButton ?? this.showShareButton,
      showDeleteButton: showDeleteButton ?? this.showDeleteButton,
      enableZoom: enableZoom ?? this.enableZoom,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      initialScale: initialScale ?? this.initialScale,
      doubleTapToZoom: doubleTapToZoom ?? this.doubleTapToZoom,
      title: title ?? this.title,
      closeTooltip: closeTooltip ?? this.closeTooltip,
      shareTooltip: shareTooltip ?? this.shareTooltip,
      deleteTooltip: deleteTooltip ?? this.deleteTooltip,
      showImageInfo: showImageInfo ?? this.showImageInfo,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }
}
