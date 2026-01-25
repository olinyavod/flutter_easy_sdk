import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Represents an image source for the viewer.
sealed class EasyImageSource {
  const EasyImageSource();

  /// Creates an image source from a file path.
  const factory EasyImageSource.file(String path) = FileImageSource;

  /// Creates an image source from a network URL.
  const factory EasyImageSource.network(String url) = NetworkImageSource;

  /// Creates an image source from memory bytes.
  const factory EasyImageSource.memory(Uint8List bytes) = MemoryImageSource;

  /// Creates an image source from an asset path.
  const factory EasyImageSource.asset(String assetPath) = AssetImageSource;

  /// Builds the appropriate ImageProvider for this source.
  ImageProvider toImageProvider();
}

/// Image source from a local file.
class FileImageSource extends EasyImageSource {
  final String path;

  const FileImageSource(this.path);

  @override
  ImageProvider toImageProvider() => FileImage(File(path));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileImageSource &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}

/// Image source from a network URL.
class NetworkImageSource extends EasyImageSource {
  final String url;

  const NetworkImageSource(this.url);

  @override
  ImageProvider toImageProvider() => CachedNetworkImageProvider(url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkImageSource &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}

/// Image source from memory bytes.
class MemoryImageSource extends EasyImageSource {
  final Uint8List bytes;

  const MemoryImageSource(this.bytes);

  @override
  ImageProvider toImageProvider() => MemoryImage(bytes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryImageSource &&
          runtimeType == other.runtimeType &&
          bytes == other.bytes;

  @override
  int get hashCode => bytes.hashCode;
}

/// Image source from an asset.
class AssetImageSource extends EasyImageSource {
  final String assetPath;

  const AssetImageSource(this.assetPath);

  @override
  ImageProvider toImageProvider() => AssetImage(assetPath);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetImageSource &&
          runtimeType == other.runtimeType &&
          assetPath == other.assetPath;

  @override
  int get hashCode => assetPath.hashCode;
}
