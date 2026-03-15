import 'package:equatable/equatable.dart';

import 'easy_attachment_file_type.dart';
import 'easy_attachment_upload_status.dart';

class EasyAttachmentItem extends Equatable {
  final String localId;
  final String? serverId;
  final String? localPath;
  final String? remoteUrl;
  final EasyAttachmentFileType type;
  final String fileName;
  final int fileSize;
  final EasyUploadStatus status;
  final String? errorMessage;
  final double downloadProgress;

  const EasyAttachmentItem({
    required this.localId,
    this.serverId,
    this.localPath,
    this.remoteUrl,
    required this.type,
    required this.fileName,
    required this.fileSize,
    this.status = EasyUploadStatus.cached,
    this.errorMessage,
    this.downloadProgress = 0.0,
  });

  bool get isImage => type == EasyAttachmentFileType.image;

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Whether the file is available locally (cached or uploaded from device).
  bool get isLocallyAvailable => localPath != null;

  EasyAttachmentItem copyWith({
    String? localId,
    String? serverId,
    String? localPath,
    String? remoteUrl,
    EasyAttachmentFileType? type,
    String? fileName,
    int? fileSize,
    EasyUploadStatus? status,
    String? errorMessage,
    double? downloadProgress,
  }) {
    return EasyAttachmentItem(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  factory EasyAttachmentItem.fromJson(Map<String, dynamic> json) {
    return EasyAttachmentItem(
      localId: json['local_id'] as String,
      serverId: json['server_id'] as String?,
      localPath: json['local_path'] as String?,
      remoteUrl: json['remote_url'] as String?,
      type: EasyAttachmentFileType.values.byName(json['type'] as String),
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int,
      status: EasyUploadStatus.values.byName(json['status'] as String),
      errorMessage: json['error_message'] as String?,
      downloadProgress: (json['download_progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'local_path': localPath,
      'remote_url': remoteUrl,
      'type': type.name,
      'file_name': fileName,
      'file_size': fileSize,
      'status': status.name,
      'error_message': errorMessage,
      'download_progress': downloadProgress,
    };
  }

  @override
  List<Object?> get props => [
        localId,
        serverId,
        localPath,
        remoteUrl,
        type,
        fileName,
        fileSize,
        status,
        errorMessage,
        downloadProgress,
      ];
}
