import 'package:equatable/equatable.dart';

import '../easy_attachment_item.dart';

class EasyAttachmentState extends Equatable {
  final List<EasyAttachmentItem> items;
  final bool isUploading;
  final String? error;
  final double uploadProgress;

  const EasyAttachmentState({
    this.items = const [],
    this.isUploading = false,
    this.error,
    this.uploadProgress = 0.0,
  });

  EasyAttachmentState copyWith({
    List<EasyAttachmentItem>? items,
    bool? isUploading,
    String? error,
    double? uploadProgress,
  }) {
    return EasyAttachmentState(
      items: items ?? this.items,
      isUploading: isUploading ?? this.isUploading,
      error: error,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  @override
  List<Object?> get props => [items, isUploading, error, uploadProgress];
}
