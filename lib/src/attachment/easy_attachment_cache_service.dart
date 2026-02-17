import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'easy_attachment_file_type.dart';
import 'easy_attachment_item.dart';
import 'easy_attachment_upload_status.dart';

class EasyAttachmentCacheService {
  static const _cacheDirName = 'attachments_cache';
  final _uuid = const Uuid();

  Future<Directory> _getCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(tempDir.path, _cacheDirName));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Copies the file to cache and returns an [EasyAttachmentItem].
  Future<EasyAttachmentItem> cacheFile(File file) async {
    final cacheDir = await _getCacheDir();
    final localId = _uuid.v4();
    final fileName = p.basename(file.path);
    final ext = p.extension(file.path);
    final cachedPath = p.join(cacheDir.path, '$localId$ext');

    await file.copy(cachedPath);
    final fileSize = await file.length();

    return EasyAttachmentItem(
      localId: localId,
      localPath: cachedPath,
      type: EasyAttachmentFileType.fromExtension(fileName),
      fileName: fileName,
      fileSize: fileSize,
      status: EasyUploadStatus.cached,
    );
  }

  /// Deletes a cached file.
  Future<void> deleteCachedFile(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clears the entire cache directory.
  Future<void> clearCache() async {
    final cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
