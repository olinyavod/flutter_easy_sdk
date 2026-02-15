import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Виджет кэшированного аватара с поддержкой локальных и сетевых изображений.
///
/// Отображает круглый аватар с рамкой. Поддерживает:
/// - Сетевые изображения с кэшированием через [CachedNetworkImage]
/// - Локальные файлы (URL с префиксом `file://`)
/// - Плейсхолдер с иконкой при отсутствии изображения
///
/// Пример использования:
/// ```dart
/// CachedAvatar(
///   imageUrl: user.avatarUrl,
///   size: 120,
///   borderColor: Colors.white,
///   borderWidth: 3,
/// )
/// ```
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color? placeholderBackgroundColor;
  final Color? placeholderIconColor;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.size = 80,
    this.borderColor,
    this.borderWidth = 3,
    this.placeholderBackgroundColor,
    this.placeholderIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor = borderColor ?? Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBorderColor,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: _buildImageWidget(theme),
      ),
    );
  }

  Widget _buildImageWidget(ThemeData theme) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(theme);
    }

    // Проверяем, это локальный файл или сетевой URL
    if (imageUrl!.startsWith('file://')) {
      final filePath = imageUrl!.substring(7); // Убираем "file://"
      final file = File(filePath);

      return Image.file(
        file,
        fit: BoxFit.cover,
        width: size - borderWidth * 2,
        height: size - borderWidth * 2,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(theme),
      );
    } else {
      // Сетевое изображение с кэшированием
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: size - borderWidth * 2,
        height: size - borderWidth * 2,
        placeholder: (context, url) => _buildPlaceholder(theme),
        errorWidget: (context, url, error) => _buildPlaceholder(theme),
      );
    }
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: size - borderWidth * 2,
      height: size - borderWidth * 2,
      color: placeholderBackgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: (size - borderWidth * 2) * 0.6,
        color: placeholderIconColor ?? theme.colorScheme.primary,
      ),
    );
  }
}
