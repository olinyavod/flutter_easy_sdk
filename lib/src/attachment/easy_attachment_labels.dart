class EasyAttachmentLabels {
  // Header
  final String Function(int count) headerTitle;

  // Picker sheet
  final String pickerTitle;
  final String pickFromGalleryTitle;
  final String pickFromGallerySubtitle;
  final String pickFromCameraTitle;
  final String pickFromCameraSubtitle;
  final String pickDocumentTitle;
  final String pickDocumentSubtitle;

  // Add tile
  final String addButtonLabel;

  // Context menu
  final String previewTitle;
  final String previewSubtitle;
  final String shareTitle;
  final String shareSubtitle;
  final String deleteTitle;
  final String deleteSubtitle;
  final String openExternalTitle;
  final String openExternalSubtitle;
  final String closeViewerTitle;
  final String closeViewerSubtitle;
  final String cancelLabel;

  // Delete confirmation
  final String deleteConfirmTitle;
  final String deleteConfirmMessage;
  final String deleteConfirmButton;
  final String deleteCancelButton;

  // Delete photo confirmation (gallery)
  final String deletePhotoConfirmTitle;
  final String deletePhotoConfirmMessage;

  // Gallery
  final String Function(int current, int total) galleryCounter;

  // Errors
  final String Function(String error) uploadErrorMessage;

  const EasyAttachmentLabels({
    this.headerTitle = _defaultHeaderTitle,
    this.pickerTitle = 'Add attachment',
    this.pickFromGalleryTitle = 'Photo from gallery',
    this.pickFromGallerySubtitle = 'Choose an existing image',
    this.pickFromCameraTitle = 'Take photo',
    this.pickFromCameraSubtitle = 'Capture with camera',
    this.pickDocumentTitle = 'Choose document',
    this.pickDocumentSubtitle = 'PDF, DOC, XLS, TXT files',
    this.addButtonLabel = 'Add',
    this.previewTitle = 'Preview',
    this.previewSubtitle = 'Open in fullscreen',
    this.shareTitle = 'Share',
    this.shareSubtitle = 'Send via another app',
    this.deleteTitle = 'Delete',
    this.deleteSubtitle = 'Delete attachment permanently',
    this.openExternalTitle = 'Open in app',
    this.openExternalSubtitle = 'Open in external app',
    this.closeViewerTitle = 'Close viewer',
    this.closeViewerSubtitle = 'Go back',
    this.cancelLabel = 'Cancel',
    this.deleteConfirmTitle = 'Delete attachment',
    this.deleteConfirmMessage =
        'This action cannot be undone. The attachment will be permanently deleted.',
    this.deleteConfirmButton = 'Delete',
    this.deleteCancelButton = 'Cancel',
    this.deletePhotoConfirmTitle = 'Delete photo',
    this.deletePhotoConfirmMessage =
        'This action cannot be undone. The photo will be permanently deleted.',
    this.galleryCounter = _defaultGalleryCounter,
    this.uploadErrorMessage = _defaultUploadError,
  });

  /// Russian locale preset.
  factory EasyAttachmentLabels.ru() => const EasyAttachmentLabels(
        headerTitle: _ruHeaderTitle,
        pickerTitle: 'Добавить вложение',
        pickFromGalleryTitle: 'Фото из галереи',
        pickFromGallerySubtitle: 'Выбрать существующее изображение',
        pickFromCameraTitle: 'Сделать фото',
        pickFromCameraSubtitle: 'Сфотографировать на камеру',
        pickDocumentTitle: 'Выбрать документ',
        pickDocumentSubtitle: 'PDF, DOC, XLS, TXT файлы',
        addButtonLabel: 'Добавить',
        previewTitle: 'Просмотреть',
        previewSubtitle: 'Открыть в полноэкранном режиме',
        shareTitle: 'Поделиться',
        shareSubtitle: 'Отправить через другое приложение',
        deleteTitle: 'Удалить',
        deleteSubtitle: 'Удалить вложение безвозвратно',
        openExternalTitle: 'Открыть в приложении',
        openExternalSubtitle: 'Открыть в стороннем приложении',
        closeViewerTitle: 'Закрыть просмотр',
        closeViewerSubtitle: 'Вернуться назад',
        cancelLabel: 'Отмена',
        deleteConfirmTitle: 'Удалить вложение',
        deleteConfirmMessage:
            'Это действие нельзя отменить. Вложение будет удалено безвозвратно.',
        deleteConfirmButton: 'Удалить',
        deleteCancelButton: 'Отмена',
        deletePhotoConfirmTitle: 'Удалить фото',
        deletePhotoConfirmMessage:
            'Это действие нельзя отменить. Фото будет удалено безвозвратно.',
        galleryCounter: _ruGalleryCounter,
        uploadErrorMessage: _ruUploadError,
      );

  static String _defaultHeaderTitle(int count) => 'Attachments ($count)';
  static String _ruHeaderTitle(int count) => 'Вложения ($count)';
  static String _defaultGalleryCounter(int c, int t) => '$c of $t';
  static String _ruGalleryCounter(int c, int t) => '$c из $t';
  static String _defaultUploadError(String e) => 'Upload error: $e';
  static String _ruUploadError(String e) => 'Ошибка загрузки: $e';
}
