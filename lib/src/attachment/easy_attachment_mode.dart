import 'package:equatable/equatable.dart';

sealed class EasyAttachmentMode extends Equatable {
  const EasyAttachmentMode();
}

/// Files are cached locally and uploaded in batch via UploadAll event.
class EasyCachedMode extends EasyAttachmentMode {
  const EasyCachedMode();

  @override
  List<Object?> get props => [];
}

/// Files are uploaded to the server immediately upon addition.
class EasyImmediateMode extends EasyAttachmentMode {
  final String entityId;
  final String? scope;

  const EasyImmediateMode({required this.entityId, this.scope});

  @override
  List<Object?> get props => [entityId, scope];
}
