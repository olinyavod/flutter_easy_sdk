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

  EasyAttachmentBloc({
    required this.mode,
    required EasyAttachmentRepository repository,
    required EasyAttachmentCacheService cacheService,
  })  : _repository = repository,
        _cacheService = cacheService,
        super(const EasyAttachmentState()) {
    on<EasyAddAttachment>(_onAddAttachment);
    on<EasyRemoveAttachment>(_onRemoveAttachment);
    on<EasyReorderAttachment>(_onReorderAttachment);
    on<EasyUploadAll>(_onUploadAll);
    on<EasyLoadExisting>(_onLoadExisting);
    on<EasyRetryUpload>(_onRetryUpload);
  }

  Future<void> _onAddAttachment(
    EasyAddAttachment event,
    Emitter<EasyAttachmentState> emit,
  ) async {
    final cached = await _cacheService.cacheFile(event.file);
    final updatedItems = [cached, ...state.items];
    emit(state.copyWith(items: updatedItems));

    if (mode is EasyImmediateMode) {
      final entityId = (mode as EasyImmediateMode).entityId;
      await _uploadSingle(cached, entityId, emit);
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
        await _repository.deleteAttachment(item.serverId!);
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
    final entityId = (mode as EasyImmediateMode).entityId;

    final item = state.items.firstWhere((i) => i.localId == event.localId);
    await _uploadSingle(item, entityId, emit);
  }

  Future<void> _uploadSingle(
    EasyAttachmentItem item,
    String entityId,
    Emitter<EasyAttachmentState> emit,
  ) async {
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
      );

      updatedItems = state.items
          .map((i) => i.localId == item.localId ? uploaded : i)
          .toList();
      emit(state.copyWith(items: updatedItems));
    } catch (e) {
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
}
