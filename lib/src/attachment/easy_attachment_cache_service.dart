import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'easy_attachment_file_type.dart';
import 'easy_attachment_item.dart';
import 'easy_attachment_upload_status.dart';

class EasyAttachmentCacheService {
  static const _cacheDirName = 'attachments_cache';
  static const _downloadDirName = 'attachments_downloads';
  final _uuid = const Uuid();
  final Dio _dio;

  EasyAttachmentCacheService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Directory> _getCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(tempDir.path, _cacheDirName));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<Directory> _getDownloadDir() async {
    final tempDir = await getTemporaryDirectory();
    final downloadDir = Directory(p.join(tempDir.path, _downloadDirName));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
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

  /// Returns the cached local path for a remote URL, or null if not cached.
  Future<String?> getCachedPath(String remoteUrl, String fileName) async {
    final downloadDir = await _getDownloadDir();
    final ext = p.extension(fileName);
    final key = remoteUrl.hashCode.toRadixString(36);
    final cachedPath = p.join(downloadDir.path, '$key$ext');
    final file = File(cachedPath);
    if (await file.exists()) {
      return cachedPath;
    }
    return null;
  }

  /// Downloads a file from [remoteUrl] to local cache.
  /// Reports progress via [onProgress] (0.0 to 1.0).
  /// Supports cancellation via [cancelToken].
  Future<String> downloadAndCache({
    required String remoteUrl,
    required String fileName,
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
  }) async {
    final downloadDir = await _getDownloadDir();
    final ext = p.extension(fileName);
    final key = remoteUrl.hashCode.toRadixString(36);
    final cachedPath = p.join(downloadDir.path, '$key$ext');

    // Already cached
    final file = File(cachedPath);
    if (await file.exists()) {
      onProgress?.call(1.0);
      return cachedPath;
    }

    await _dio.download(
      remoteUrl,
      cachedPath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received / total);
        }
      },
    );

    return cachedPath;
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
    final downloadDir = await _getDownloadDir();
    if (await downloadDir.exists()) {
      await downloadDir.delete(recursive: true);
    }
  }
}
