import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/easy_attachment_bloc.dart';
import 'bloc/easy_attachment_event.dart';
import 'bloc/easy_attachment_state.dart';
import 'easy_attachment_config.dart';
import 'easy_attachment_item.dart';
import 'easy_attachment_upload_status.dart';

class EasyAttachmentGalleryPage extends StatefulWidget {
  final List<EasyAttachmentItem> images;
  final int initialIndex;
  final bool editable;
  final void Function(String localId)? onDelete;
  final EasyAttachmentConfig config;

  const EasyAttachmentGalleryPage({
    super.key,
    required this.images,
    required this.initialIndex,
    this.editable = false,
    this.onDelete,
    required this.config,
  });

  @override
  State<EasyAttachmentGalleryPage> createState() =>
      _EasyAttachmentGalleryPageState();
}

class _EasyAttachmentGalleryPageState extends State<EasyAttachmentGalleryPage> {
  late final PageController _pageController;
  late List<EasyAttachmentItem> _images;
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _images = List.of(widget.images);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onZoomChanged(bool zoomed) {
    if (_isZoomed != zoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  EasyAttachmentItem get _currentItem => _images[_currentIndex];
  EasyAttachmentConfig get _config => widget.config;

  void _showGalleryMenu() {
    final theme = Theme.of(context);
    final labels = _config.labels;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    const menuOffset = Offset(16, 80);
    final position = RelativeRect.fromLTRB(
      menuOffset.dx,
      menuOffset.dy,
      overlay.size.width - menuOffset.dx,
      overlay.size.height - menuOffset.dy,
    );

    final items = <PopupMenuEntry<String>>[
      if (_config.onShare != null)
        _popupItem(theme, 'share', Icons.share, labels.shareTitle),
      if (_config.onOpenExternal != null)
        _popupItem(
            theme, 'open', Icons.open_in_new, labels.openExternalTitle),
      if (widget.editable)
        _popupItem(
            theme, 'delete', Icons.delete_outline, labels.deleteTitle,
            isDestructive: true),
    ];

    showMenu<String>(
      context: context,
      position: position,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: items,
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'share':
          _shareCurrentFile();
        case 'open':
          _openInExternalApp();
        case 'delete':
          _deleteCurrentPhoto();
      }
    });
  }

  PopupMenuItem<String> _popupItem(
    ThemeData theme,
    String value,
    IconData icon,
    String title, {
    bool isDestructive = false,
  }) {
    final color =
        isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  void _shareCurrentFile() {
    final item = _currentItem;
    if (item.localPath != null) {
      _config.onShare?.call(item.localPath!);
      return;
    }
    // Download then share
    final bloc = context.read<EasyAttachmentBloc>();
    bloc.onDownloadComplete = (localId, path) {
      if (localId == item.localId) {
        _config.onShare?.call(path);
        bloc.onDownloadComplete = null;
      }
    };
    bloc.add(EasyDownloadFile(item.localId));
  }

  void _openInExternalApp() {
    final item = _currentItem;
    if (item.localPath != null) {
      _config.onOpenExternal?.call(item.localPath!);
      return;
    }
    final bloc = context.read<EasyAttachmentBloc>();
    bloc.onDownloadComplete = (localId, path) {
      if (localId == item.localId) {
        _config.onOpenExternal?.call(path);
        bloc.onDownloadComplete = null;
      }
    };
    bloc.add(EasyDownloadFile(item.localId));
  }

  void _deleteCurrentPhoto() {
    final item = _currentItem;
    final labels = _config.labels;

    void doDelete() {
      widget.onDelete?.call(item.localId);
      if (_images.length <= 1) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _images.removeAt(_currentIndex);
        if (_currentIndex >= _images.length) {
          _currentIndex = _images.length - 1;
        }
      });
      _pageController.jumpToPage(_currentIndex);
    }

    if (_config.onDeleteConfirm != null) {
      _config.onDeleteConfirm!(context, doDelete);
    } else {
      _showDefaultDeleteDialog(
        context,
        title: labels.deletePhotoConfirmTitle,
        message: labels.deletePhotoConfirmMessage,
        confirmText: labels.deleteConfirmButton,
        cancelText: labels.deleteCancelButton,
        onConfirm: doDelete,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _config.labels;

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocListener<EasyAttachmentBloc, EasyAttachmentState>(
        listenWhen: (prev, curr) {
          // Listen for download state changes on current item
          final prevItem = prev.items
              .where((i) => i.localId == _currentItem.localId)
              .firstOrNull;
          final currItem = curr.items
              .where((i) => i.localId == _currentItem.localId)
              .firstOrNull;
          return prevItem?.status != currItem?.status ||
              prevItem?.downloadProgress != currItem?.downloadProgress;
        },
        listener: (context, state) {
          // Update local images list from bloc state
          for (int i = 0; i < _images.length; i++) {
            final updated = state.items
                .where((si) => si.localId == _images[i].localId)
                .firstOrNull;
            if (updated != null) {
              _images[i] = updated;
            }
          }
          setState(() {});
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              physics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final item = _images[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _EasyZoomableImage(
                      item: item,
                      onZoomChanged: _onZoomChanged,
                    ),
                    // Telegram-style download overlay in gallery
                    if (item.status == EasyUploadStatus.downloading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: Center(
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: CircularProgressIndicator(
                                    value: item.downloadProgress > 0
                                        ? item.downloadProgress
                                        : null,
                                    strokeWidth: 3,
                                    color: Colors.white,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context
                                      .read<EasyAttachmentBloc>()
                                      .add(EasyCancelDownload(item.localId)),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: _showGalleryMenu,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _images[_currentIndex].fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                labels.galleryCounter(
                                    _currentIndex + 1, _images.length),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showDefaultDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  required String cancelText,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

class _EasyZoomableImage extends StatefulWidget {
  final EasyAttachmentItem item;
  final ValueChanged<bool> onZoomChanged;

  const _EasyZoomableImage({
    required this.item,
    required this.onZoomChanged,
  });

  @override
  State<_EasyZoomableImage> createState() => _EasyZoomableImageState();
}

class _EasyZoomableImageState extends State<_EasyZoomableImage>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _controller.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformChanged);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    widget.onZoomChanged(scale > 1.05);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final scale = _controller.value.getMaxScaleOnAxis();
    if (scale > 1.05) {
      _animateTo(Matrix4.identity());
    } else {
      const targetScale = 3.0;
      final position = details.localPosition;
      final target = Matrix4.identity()
        ..setEntry(0, 3, position.dx * (1 - targetScale))
        ..setEntry(1, 3, position.dy * (1 - targetScale))
        ..setEntry(0, 0, targetScale)
        ..setEntry(1, 1, targetScale);
      _animateTo(target);
    }
  }

  void _animateTo(Matrix4 target) {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animation!.addListener(() {
      _controller.value = _animation!.value;
    });
    _animationController.forward(from: 0);
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final scale = _controller.value.getMaxScaleOnAxis();
    if (scale < 1.0) {
      _animateTo(Matrix4.identity());
    }
  }

  ImageProvider _imageProvider() {
    if (widget.item.localPath != null) {
      return FileImage(File(widget.item.localPath!));
    }
    if (widget.item.remoteUrl != null) {
      return NetworkImage(widget.item.remoteUrl!);
    }
    return const AssetImage('assets/images/placeholder.png');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: () {},
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 0.5,
        maxScale: 5.0,
        onInteractionEnd: _onInteractionEnd,
        child: Center(
          child: Image(
            image: _imageProvider(),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}
