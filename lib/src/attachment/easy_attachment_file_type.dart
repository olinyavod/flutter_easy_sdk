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
}
