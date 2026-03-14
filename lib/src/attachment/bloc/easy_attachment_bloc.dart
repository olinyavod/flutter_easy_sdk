import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../easy_attachment_cache_service.dart';
import '../easy_attachment_item.dart';
import '../easy_attachment_mode.dart';
import '../easy_attachment_repository.dart';
import '../easy_attachment_upload_status.dart';
import 'easy_attachment_event.dart';
import 'easy_attachment_state.dart';

class EasyAttachmentBloc
    extends Bloc<EasyAttachmentEvent, EasyAttachmentState> {
  final EasyAttachmentMode mode;
  final EasyAttachmentRepository _repository;
  final EasyAttachmentCacheService _cacheService;
  final Map<String, CancelToken> _cancelTokens = {};

  /// Максимальный размер файла в байтах. null — без ограничений.
  final int? maxFileSize;

  /// Сообщение об ошибке при превышении лимита.
  final String Function(int maxSizeMb)? fileTooLargeMessage;

  EasyAttachmentBloc({
    required this.mode,
    required EasyAttachmentRepository repository,
    required EasyAttachmentCacheService cacheService,
    this.maxFileSize,
    this.fileTooLargeMessage,
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
  }

  Future<void> _onAddAttachment(
    EasyAddAttachment event,
    Emitter<EasyAttachmentState> emit,
  ) async {
    final cached = await _cacheService.cacheFile(event.file);

    // Проверка размера файла
    if (maxFileSize != null && cached.fileSize > maxFileSize!) {
      final maxMb = maxFileSize! ~/ (1024 * 1024);
      final message = fileTooLargeMessage?.call(maxMb) ??
          'Файл слишком большой. Максимальный размер: $maxMb МБ';

      // Удаляем закешированный файл
      if (cached.localPath != null) {
        await _cacheService.deleteCachedFile(cached.localPath!);
      }

      final errorItem = cached.copyWith(
        status: EasyUploadStatus.error,
        errorMessage: message,
      );
      final updatedItems = [errorItem, ...state.items];
      emit(state.copyWith(items: updatedItems));
      return;
    }

    final updatedItems = [cached, ...state.items];
    emit(state.copyWith(items: updatedItems));

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
      } catch (_) {
        // Ignore server deletion errors
      }
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

    final updatedItems = state.items
        .map((i) => i.localId == event.localId
            ? i.copyWith(status: EasyUploadStatus.cached, errorMessage: null)
            : i)
        .toList();
    emit(state.copyWith(items: updatedItems));
  }

  Future<void> _uploadSingle(
    EasyAttachmentItem item,
    String entityId,
    Emitter<EasyAttachmentState> emit, {
    String? scope,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.localId] = cancelToken;

    var updatedItems = state.items
        .map((i) => i.localId == item.localId
            ? i.copyWith(status: EasyUploadStatus.uploading)
            : i)
        .toList();
    emit(state.copyWith(items: updatedItems));

    try {
      final uploaded = await _repository.uploadAttachment(
        item: item,
        entityId: entityId,
        scope: scope,
        cancelToken: cancelToken,
      );

      _cancelTokens.remove(item.localId);

      updatedItems = state.items
          .map((i) => i.localId == item.localId ? uploaded : i)
          .toList();
      emit(state.copyWith(items: updatedItems));
    } on DioException catch (e) {
      _cancelTokens.remove(item.localId);
      if (e.type == DioExceptionType.cancel) return;

      updatedItems = state.items
          .map((i) => i.localId == item.localId
              ? i.copyWith(
                  status: EasyUploadStatus.error,
                  errorMessage: e.message,
                )
              : i)
          .toList();
      emit(state.copyWith(items: updatedItems));
    } catch (e) {
      _cancelTokens.remove(item.localId);

      updatedItems = state.items
          .map((i) => i.localId == item.localId
              ? i.copyWith(
                  status: EasyUploadStatus.error,
                  errorMessage: e.toString(),
                )
              : i)
          .toList();
      emit(state.copyWith(items: updatedItems));
    }
  }

  @override
  Future<void> close() {
    for (final token in _cancelTokens.values) {
      token.cancel('BLoC closed');
    }
    _cancelTokens.clear();
    return super.close();
  }
}
