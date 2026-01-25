import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:equatable/equatable.dart';

/// Persistent camera settings that can be saved and restored.
class EasyCameraSettings extends Equatable {
  /// Flash mode (auto, on, off, always).
  final FlashMode flashMode;

  /// Camera position (front or back).
  final SensorPosition cameraPosition;

  /// Zoom level (0.0 - 1.0).
  final double zoomLevel;

  /// Image quality (0.0 - 1.0).
  final double imageQuality;

  const EasyCameraSettings({
    this.flashMode = FlashMode.auto,
    this.cameraPosition = SensorPosition.back,
    this.zoomLevel = 0.0,
    this.imageQuality = 0.85,
  });

  /// Creates settings from a JSON map.
  factory EasyCameraSettings.fromJson(Map<String, dynamic> json) {
    return EasyCameraSettings(
      flashMode: FlashMode.values.firstWhere(
        (e) => e.name == json['flashMode'],
        orElse: () => FlashMode.auto,
      ),
      cameraPosition: SensorPosition.values.firstWhere(
        (e) => e.name == json['cameraPosition'],
        orElse: () => SensorPosition.back,
      ),
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 0.0,
      imageQuality: (json['imageQuality'] as num?)?.toDouble() ?? 0.85,
    );
  }

  /// Converts settings to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'flashMode': flashMode.name,
      'cameraPosition': cameraPosition.name,
      'zoomLevel': zoomLevel,
      'imageQuality': imageQuality,
    };
  }

  /// Creates a copy with updated values.
  EasyCameraSettings copyWith({
    FlashMode? flashMode,
    SensorPosition? cameraPosition,
    double? zoomLevel,
    double? imageQuality,
  }) {
    return EasyCameraSettings(
      flashMode: flashMode ?? this.flashMode,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      imageQuality: imageQuality ?? this.imageQuality,
    );
  }

  @override
  List<Object?> get props => [flashMode, cameraPosition, zoomLevel, imageQuality];

  @override
  String toString() =>
      'EasyCameraSettings(flash: $flashMode, camera: $cameraPosition, zoom: $zoomLevel, quality: $imageQuality)';
}
