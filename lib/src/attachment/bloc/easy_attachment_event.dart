import 'dart:io';

import 'package:equatable/equatable.dart';

import '../easy_attachment_item.dart';

sealed class EasyAttachmentEvent extends Equatable {
  const EasyAttachmentEvent();

  @override
  List<Object?> get props => [];
}

class EasyAddAttachment extends EasyAttachmentEvent {
  final File file;

  const EasyAddAttachment(this.file);

  @override
  List<Object?> get props => [file.path];
}

class EasyRemoveAttachment extends EasyAttachmentEvent {
  final String localId;

  const EasyRemoveAttachment(this.localId);

  @override
  List<Object?> get props => [localId];
}

class EasyReorderAttachment extends EasyAttachmentEvent {
  final int oldIndex;
  final int newIndex;

  const EasyReorderAttachment(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class EasyUploadAll extends EasyAttachmentEvent {
  final String entityId;

  const EasyUploadAll(this.entityId);

  @override
  List<Object?> get props => [entityId];
}

class EasyLoadExisting extends EasyAttachmentEvent {
  final List<EasyAttachmentItem> items;

  const EasyLoadExisting(this.items);

  @override
  List<Object?> get props => [items];
}

class EasyRetryUpload extends EasyAttachmentEvent {
  final String localId;

  const EasyRetryUpload(this.localId);

  @override
  List<Object?> get props => [localId];
}
