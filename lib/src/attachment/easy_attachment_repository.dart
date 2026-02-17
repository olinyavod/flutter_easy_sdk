import 'easy_attachment_item.dart';

/// Abstract interface for attachment upload/download operations.
///
/// The app must provide a concrete implementation that communicates
/// with its own API.
abstract class EasyAttachmentRepository {
  Future<EasyAttachmentItem> uploadAttachment({
    required EasyAttachmentItem item,
    required String entityId,
  });

  Future<List<EasyAttachmentItem>> getAttachments(String entityId);

  Future<bool> deleteAttachment(String serverId);

  Future<List<EasyAttachmentItem>> uploadBatch({
    required List<EasyAttachmentItem> items,
    required String entityId,
  });
}
