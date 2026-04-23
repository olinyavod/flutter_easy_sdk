import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Shares files via the native system share sheet.
///
/// Works around two common iOS quirks:
/// 1. Some messengers convert `.txt` files to plain message text instead of
///    attaching them. Always providing an explicit MIME type + passing the
///    file through `UIActivityViewController` with a proper extension
///    reduces the chance of this happening.
/// 2. Files in the app's Documents directory can sometimes be inaccessible to
///    other apps. Copying to the temporary directory with a unique name
///    avoids this class of issues and guarantees a fresh file for every share.
class EasyFileShareService {
  const EasyFileShareService();

  /// Shares [file] via the native share sheet.
  ///
  /// If [mimeType] is omitted it is inferred from the file extension.
  /// If [ensureFreshCopy] is true (default), the file is always copied to the
  /// temporary directory with a timestamped filename so each share is a
  /// distinct file — useful for logs and dynamically-generated content.
  Future<void> shareFile(
    File file, {
    String? mimeType,
    String? text,
    String? subject,
    bool ensureFreshCopy = true,
  }) async {
    if (!await file.exists()) {
      throw FileSystemException('File to share does not exist', file.path);
    }

    final resolvedMime = mimeType ?? detectMimeType(file.path);
    final prepared = ensureFreshCopy || !_extensionMatchesMime(file.path, resolvedMime)
        ? await _copyToTemp(file, resolvedMime)
        : file;

    await Share.shareXFiles(
      [XFile(prepared.path, mimeType: resolvedMime)],
      text: text,
      subject: subject,
    );
  }

  Future<File> _copyToTemp(File source, String mimeType) async {
    final tempDir = await getTemporaryDirectory();
    final baseName = p.basenameWithoutExtension(source.path);
    final extension = extensionForMime(mimeType, fallback: p.extension(source.path));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = '${tempDir.path}/share_${baseName}_$timestamp$extension';
    return source.copy(targetPath);
  }

  bool _extensionMatchesMime(String path, String mimeType) {
    final ext = p.extension(path).toLowerCase();
    return detectMimeType(path) == mimeType && ext.isNotEmpty;
  }

  /// Returns the canonical file extension (including leading dot) for the
  /// given MIME type. Falls back to [fallback] when unknown.
  static String extensionForMime(String mimeType, {String fallback = ''}) {
    return switch (mimeType) {
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      'image/gif' => '.gif',
      'image/webp' => '.webp',
      'image/bmp' => '.bmp',
      'image/heic' => '.heic',
      'text/plain' => '.txt',
      'text/csv' => '.csv',
      'text/html' => '.html',
      'application/json' => '.json',
      'application/pdf' => '.pdf',
      'application/zip' => '.zip',
      _ => fallback.isNotEmpty ? fallback : '.bin',
    };
  }

  /// Detects MIME type from the file extension. Returns
  /// `application/octet-stream` when the extension is unknown.
  static String detectMimeType(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.bmp' => 'image/bmp',
      '.heic' => 'image/heic',
      '.txt' || '.log' => 'text/plain',
      '.csv' => 'text/csv',
      '.html' || '.htm' => 'text/html',
      '.json' => 'application/json',
      '.pdf' => 'application/pdf',
      '.zip' => 'application/zip',
      _ => 'application/octet-stream',
    };
  }
}
