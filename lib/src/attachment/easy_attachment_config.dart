import 'dart:io';

import 'package:flutter/material.dart';

import 'easy_attachment_labels.dart';

class EasyAttachmentConfig {
  /// Labels for all user-facing text.
  final EasyAttachmentLabels labels;

  /// Size of each attachment tile (width and height).
  final double tileSize;

  /// Spacing between tiles.
  final double tileSpacing;

  /// Border radius of tiles.
  final double tileBorderRadius;

  /// Whether to show the document picker option.
  final bool enableDocumentPicker;

  /// Called when user picks a photo from gallery.
  /// App provides this to integrate its own image picker.
  final Future<File?> Function(BuildContext context)? onPickFromGallery;

  /// Called when user picks a photo from camera.
  final Future<File?> Function(BuildContext context)? onPickFromCamera;

  /// Called when user picks a document.
  final Future<File?> Function(BuildContext context)? onPickDocument;

  /// Called when user requests to share a file.
  /// If null, the share option is hidden.
  final void Function(String filePath)? onShare;

  /// Called when user requests to open file in an external app.
  /// If null, the option is hidden.
  final void Function(String filePath)? onOpenExternal;

  /// Custom delete confirmation dialog.
  /// If null, a default [AlertDialog] is used.
  /// Must call [onConfirm] if user confirms deletion.
  final void Function(BuildContext context, VoidCallback onConfirm)?
      onDeleteConfirm;

  const EasyAttachmentConfig({
    this.labels = const EasyAttachmentLabels(),
    this.tileSize = 100.0,
    this.tileSpacing = 8.0,
    this.tileBorderRadius = 8.0,
    this.enableDocumentPicker = true,
    this.onPickFromGallery,
    this.onPickFromCamera,
    this.onPickDocument,
    this.onShare,
    this.onOpenExternal,
    this.onDeleteConfirm,
  });

  EasyAttachmentConfig copyWith({
    EasyAttachmentLabels? labels,
    double? tileSize,
    double? tileSpacing,
    double? tileBorderRadius,
    bool? enableDocumentPicker,
    Future<File?> Function(BuildContext context)? onPickFromGallery,
    Future<File?> Function(BuildContext context)? onPickFromCamera,
    Future<File?> Function(BuildContext context)? onPickDocument,
    void Function(String filePath)? onShare,
    void Function(String filePath)? onOpenExternal,
    void Function(BuildContext context, VoidCallback onConfirm)?
        onDeleteConfirm,
  }) {
    return EasyAttachmentConfig(
      labels: labels ?? this.labels,
      tileSize: tileSize ?? this.tileSize,
      tileSpacing: tileSpacing ?? this.tileSpacing,
      tileBorderRadius: tileBorderRadius ?? this.tileBorderRadius,
      enableDocumentPicker: enableDocumentPicker ?? this.enableDocumentPicker,
      onPickFromGallery: onPickFromGallery ?? this.onPickFromGallery,
      onPickFromCamera: onPickFromCamera ?? this.onPickFromCamera,
      onPickDocument: onPickDocument ?? this.onPickDocument,
      onShare: onShare ?? this.onShare,
      onOpenExternal: onOpenExternal ?? this.onOpenExternal,
      onDeleteConfirm: onDeleteConfirm ?? this.onDeleteConfirm,
    );
  }
}
