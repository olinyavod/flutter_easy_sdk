import 'dart:io';

import 'package:equatable/equatable.dart';

/// Result of a camera capture operation.
class EasyCameraResult extends Equatable {
  /// Path to the captured image file.
  final String filePath;

  /// Optional metadata about the capture.
  final Map<String, dynamic>? metadata;

  const EasyCameraResult({
    required this.filePath,
    this.metadata,
  });

  /// Returns the captured image as a File.
  File get file => File(filePath);

  /// Checks if the file exists.
  Future<bool> get exists => file.exists();

  @override
  List<Object?> get props => [filePath, metadata];

  @override
  String toString() => 'EasyCameraResult(filePath: $filePath)';
}
