import 'package:path/path.dart' as p;

enum EasyAttachmentFileType {
  image,
  pdf,
  doc,
  other;

  static EasyAttachmentFileType fromExtension(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return switch (ext) {
      '.jpg' || '.jpeg' || '.png' || '.gif' || '.bmp' || '.webp' => image,
      '.pdf' => pdf,
      '.doc' || '.docx' || '.xls' || '.xlsx' || '.txt' => doc,
      _ => other,
    };
  }

  static EasyAttachmentFileType fromMime(String mime) {
    final lower = mime.toLowerCase();
    if (lower.startsWith('image/')) {
      return image;
    }
    if (lower == 'application/pdf') {
      return pdf;
    }
    if (lower.contains('msword') ||
        lower.contains('wordprocessingml') ||
        lower.contains('spreadsheetml') ||
        lower.contains('ms-excel') ||
        lower == 'text/plain') {
      return doc;
    }
    return other;
  }
}
