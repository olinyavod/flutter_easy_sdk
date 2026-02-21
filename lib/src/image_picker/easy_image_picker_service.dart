import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Сервис для выбора изображений из галереи и камеры.
///
/// Предоставляет методы для выбора изображений с возможностью
/// интеграции кастомной камеры через [customCameraPicker].
///
/// Пример использования:
/// ```dart
/// final service = EasyImagePickerService(
///   customCameraPicker: (context) async {
///     // Открыть кастомную камеру и вернуть файл
///     return capturedFile;
///   },
/// );
///
/// final file = await service.showImageSourceDialog(context);
/// ```
class EasyImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Опциональный колбэк для кастомной камеры.
  /// Если задан, используется вместо стандартной камеры в диалогах.
  final Future<File?> Function(BuildContext context)? customCameraPicker;

  EasyImagePickerService({this.customCameraPicker});

  /// Выбирает изображение из галереи.
  Future<File?> pickAndCropFromGallery(BuildContext context) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Делает фото со стандартной камеры.
  Future<File?> pickAndCropFromCamera(BuildContext context) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Делает фото с кастомной камеры (если задана) или стандартной.
  Future<File?> pickFromCustomCamera(BuildContext context) async {
    if (customCameraPicker != null) {
      return customCameraPicker!(context);
    }
    return pickAndCropFromCamera(context);
  }

  /// Показывает диалог выбора источника изображения (галерея / стандартная камера).
  Future<File?> showImageSourceDialog(BuildContext context) async {
    final theme = Theme.of(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Выберите источник',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Галерея',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Камера',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null || !context.mounted) return null;

    if (source == ImageSource.gallery) {
      return pickAndCropFromGallery(context);
    } else {
      return pickAndCropFromCamera(context);
    }
  }

  /// Показывает диалог выбора источника с кастомной камерой.
  ///
  /// Если [customCameraPicker] не задан, используется стандартная камера.
  Future<File?> showImageSourceDialogWithCustomCamera(
    BuildContext context,
  ) async {
    final theme = Theme.of(context);

    final useCustomCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Выберите источник',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Галерея',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Камера',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (useCustomCamera == null || !context.mounted) return null;

    if (useCustomCamera) {
      return pickFromCustomCamera(context);
    } else {
      return pickAndCropFromGallery(context);
    }
  }
}
