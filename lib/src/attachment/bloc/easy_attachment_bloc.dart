import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../easy_attachment_cache_service.dart';
import '../easy_attachment_item.dart';
import '../easy_attachment_mode.dart';
import '../easy_attachment_repository.dart';
import '../easy_attachment_upload_status.dart';
import 'easy_attachment_event.dart';
import 'easy_attachment_state.dart';

/// Internal sealed type for download stream events.
sealed class _DownloadUpdate {}

class _DownloadProgress extends _DownloadUpdate {
  final double progress;
  _DownloadProgress(this.progress);
}

class _DownloadDone extends _DownloadUpdate {
  final String localPath;
  _DownloadDone(this.localPath);
}

class _DownloadError extends _DownloadUpdate {
  final Object error;
  final bool cancelled;
  _DownloadError(this.error, {this.cancelled = false});
}

class EasyAttachmentBloc
    extends Bloc<EasyAttachmentEvent, EasyAttachmentState> {
  final EasyAttachmentMode mode;
  final EasyAttachmentRepository _repository;
  final EasyAttachmentCacheService _cacheService;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, CancelToken> _downloadCancelTokens = {};

  /// Максимальный размер файла в байтах. null — без ограничений.
  final int? maxFileSize;

  /// Сообщение об ошибке при превышении лимита.
  final String Function(int maxSizeMb)? fileTooLargeMessage;

  /// Called when a file download completes successfully.
  void Function(String localId, String localPath)? onDownloadComplete;

  EasyAttachmentBloc({
    required this.mode,
    required EasyAttachmentRepository repository,
    required EasyAttachmentCacheService cacheService,
    this.maxFileSize,
    this.fileTooLargeMessage,
    this.onDownloadComplete,
  })  : _repository = repository,
        _cacheService = cacheService,
        super(const EasyAttachmentState()) {
    on<EasyAddAttachment>(_onAddAttachment);
    on<EasyRemoveAttachment>(_onRemoveAttachment);
    on<EasyReorderAttachment>(_onReorderAttachment);
    on<EasyUploadAll>(_onUploadAll);
    on<EasyLoadExisting>(_onLoadExisting);
    on<EasyRetryUpload>(_onRetryUpload);
    on<EasyCancelUpload>(_onCancelUpload);
    on<EasyDownloadFile>(_onDownloadFile);
    on<EasyCancelDownload>(_onCancelDownload);
  }

  List<EasyAttachmentItem> _updateItem(
    String localId,
    EasyAttachmentItem Function(EasyAttachmentItem) updater,
  ) {
    return state.items
        .map((i) => i.localId == localId ? updater(i) : i)
        .toList();
  }

  Future<void> _onAddAttachment(
    EasyAddAttachment event,
    Emitter<EasyAttachmentState> emit,
  ) async {
    final cached = await _cacheService.cacheFile(event.file);

    if (maxFileSize != null && cached.fileSize > maxFileSize!) {
      final maxMb = maxFileSize! ~/ (1024 * 1024);
      final message = fileTooLargeMessage?.call(maxMb) ??
          'Файл слишком большой. Максимальный размер: $maxMb МБ';

      if (cached.localPath != null) {
        await _cacheService.deleteCachedFile(cached.localPath!);
      }

      emit(state.copyWith(error: message));
      return;
    }

    emit(state.copyWith(items: [cached, ...state.items]));

    if (mode is EasyImmediateMode) {
      final immediateMode = mode as EasyImmediateMode;
      await _uploadSingle(cached, immediateMode.entityId, emit,
          scope: immediateMode.scope);
    }
  }

  Future<void> _onRemoveAttachment(
    EasyRemoveAttachment event,
    Emitter<EasyAttachmentState> emit,
  ) async {
    final item = state.items.firstWhere((i) => i.localId == event.localId);

    if (item.localPath != null) {
      await _cacheService.deleteCachedFile(item.localPath!);
    }

    if (mode is EasyImmediateMode && item.serverId != null) {
      try {
        await _repository.deleteAttachment(
          item.serverId!,
          entityId: (mode as EasyImmediateMode).entityId,
        );
      } catch (_) {}
    }

    final updatedItems =
        state.items.where((i) => i.localId != event.localId).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onReorderAttachment(
    EasyReorderAttachment event,
    Emitter<EasyAttachmentState> emit,
  ) {
    final items = [...state.items];
    final item = items.removeAt(event.oldIndex);
    var newIndex = event.newIndex;
    if (event.oldIndex < newIndex) newIndex--;
    items.insert(newIndex, item);
    emit(state.copyWith(items: items));
  }

  Future<void> _onUploadAll(
    EasyUploadAll event,
    Emitter<EasyAttachmentState> emit,
  ) async {
    final cachedItems = state.items
        .where((i) => i.status == EasyUploadStatus.cached)
        .toList();
    if (cachedItems.isEmpty) return;

    emit(state.copyWith(isUploading: true, uploadProgress: 0.0));

    try {
      final uploaded = await _repository.uploadBatch(
        items: cachedItems,
        entityId: event.entityId,
      );

      final updatedItems = state.items.map((item) {
        final match = uploaded.where((u) => u.localId == item.localId);
        if (match.isNotEmpty) return match.first;
        return item;
      }).toList();

      emit(state.copyWith(
        items: updatedItems,
        isUploading: false,
        uploadProgress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        error: e.toString(),
      ));
    }
  }

  void _onLoadExisting(
    EasyLoadExisting event,
    Emitter<EasyAttachmentState> emit,
  ) {
    emit(state.copyWith(items: event.items));
  }

  Future<void> _onRetryUpload(
    EasyRetryUpload event,
    Emitter<EasyAttachmentState> emit,
  ) async {
    if (mode is! EasyImmediateMode) return;
    final immediateMode = mode as EasyImmediateMode;

    final item = state.items.firstWhere((i) => i.localId == event.localId);
    await _uploadSingle(item, immediateMode.entityId, emit,
        scope: immediateMode.scope);
  }

  void _onCancelUpload(
    EasyCancelUpload event,
    Emitter<EasyAttachmentState> emit,
  ) {
    final cancelToken = _cancelTokens.remove(event.localId);
    cancelToken?.cancel('Upload cancelled by user');

    emit(state.copyWith(
      items: _updateItem(
          event.localId,
          (i) =>
              i.copyWith(status: EasyUploadStatus.cached, errorMessage: null)),
    ));
  }

  Stream<_DownloadUpdate> _downloadStream({
    required String remoteUrl,
    required String fileName,
    required CancelToken cancelToken,
  }) async* {
    final controller = StreamController<_DownloadUpdate>();

    final downloadFuture = _cacheService
        .downloadAndCache(
      remoteUrl: remoteUrl,
      fileName: fileName,
      cancelToken: cancelToken,
      onProgress: (progress) {
        if (!controller.isClosed) {
          controller.add(_DownloadProgress(progress));
        }
      },
    )
        .then((path) {
      if (!controller.isClosed) {
        controller.add(_DownloadDone(path));
        controller.close();
      }
    }).catchError((Object e) {
      if (!controller.isClosed) {
        final cancelled =
            e is DioException && e.type == DioExceptionType.cancel;
        controller.add(_DownloadError(e, cancelled: cancelled));
        controller.close();
      }
    });

    yield* controller.stream;
    await downloadFuture.catchError((_) {});
  }

  Future<void> _onDownloadFile(
    EasyDownloadFile event,
    Emitter<EasyAttachmentState> emit,
  ) async {
    final item = state.items.firstWhere((i) => i.localId == event.localId);

    // Already have local file
    if (item.localPath != null) {
      onDownloadComplete?.call(item.localId, item.localPath!);
      return;
    }

    if (item.remoteUrl == null) return;

    // Check if already cached
    final existingPath =
        await _cacheService.getCachedPath(item.remoteUrl!, item.fileName);
    if (existingPath != null) {
      emit(state.copyWith(
        items: _updateItem(event.localId,
            (i) => i.copyWith(localPath: existingPath, downloadProgress: 1.0)),
      ));
      onDownloadComplete?.call(item.localId, existingPath);
      return;
    }

    // Start downloading
    final cancelToken = CancelToken();
    _downloadCancelTokens[event.localId] = cancelToken;

    emit(state.copyWith(
      items: _updateItem(
          event.localId,
          (i) => i.copyWith(
              status: EasyUploadStatus.downloading, downloadProgress: 0.0)),
    ));

    String? completedPath;

    await emit.forEach<_DownloadUpdate>(
      _downloadStream(
        remoteUrl: item.remoteUrl!,
        fileName: item.fileName,
        cancelToken: cancelToken,
      ),
      onData: (update) {
        switch (update) {
          case _DownloadProgress(:final progress):
            return state.copyWith(
              items: _updateItem(event.localId,
                  (i) => i.copyWith(downloadProgress: progress)),
            );
          case _DownloadDone(:final localPath):
            _downloadCancelTokens.remove(event.localId);
            completedPath = localPath;
            return state.copyWith(
              items: _updateItem(
                  event.localId,
                  (i) => i.copyWith(
                        localPath: localPath,
                        status: EasyUploadStatus.uploaded,
                        downloadProgress: 1.0,
                      )),
            );
          case _DownloadError(:final cancelled):
            _downloadCancelTokens.remove(event.localId);
            return state.copyWith(
              items: _updateItem(
                  event.localId,
                  (i) => i.copyWith(
                        status: EasyUploadStatus.uploaded,
                        downloadProgress: 0.0,
                        errorMessage: cancelled ? null : update.error.toString(),
                      )),
            );
        }
      },
    );

    if (completedPath != null) {
      onDownloadComplete?.call(event.localId, completedPath!);
    }
  }

  void _onCancelDownload(
    EasyCancelDownload event,
    Emitter<EasyAttachmentState> emit,
  ) {
    final cancelToken = _downloadCancelTokens.remove(event.localId);
    cancelToken?.cancel('Download cancelled by user');
  }

  Future<void> _uploadSingle(
    EasyAttachmentItem item,
    String entityId,
    Emitter<EasyAttachmentState> emit, {
    String? scope,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.localId] = cancelToken;

    emit(state.copyWith(
      items: _updateItem(
          item.localId, (i) => i.copyWith(status: EasyUploadStatus.uploading)),
    ));

    try {
      final uploaded = await _repository.uploadAttachment(
        item: item,
        entityId: entityId,
        scope: scope,
        cancelToken: cancelToken,
      );

      _cancelTokens.remove(item.localId);

      emit(state.copyWith(
        items: state.items
            .map((i) => i.localId == item.localId ? uploaded : i)
            .toList(),
      ));
    } on DioException catch (e) {
      _cancelTokens.remove(item.localId);
      if (e.type == DioExceptionType.cancel) return;

      emit(state.copyWith(
        items: _updateItem(
            item.localId,
            (i) => i.copyWith(
                  status: EasyUploadStatus.error,
                  errorMessage: e.message,
                )),
      ));
    } catch (e) {
      _cancelTokens.remove(item.localId);

      emit(state.copyWith(
        items: _updateItem(
            item.localId,
            (i) => i.copyWith(
                  status: EasyUploadStatus.error,
                  errorMessage: e.toString(),
                )),
      ));
    }
  }

  @override
  Future<void> close() {
    for (final token in _cancelTokens.values) {
      token.cancel('BLoC closed');
    }
    _cancelTokens.clear();
    for (final token in _downloadCancelTokens.values) {
      token.cancel('BLoC closed');
    }
    _downloadCancelTokens.clear();
    return super.close();
  }
}
