import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/easy_bottom_sheet_widgets.dart';
import 'bloc/easy_attachment_bloc.dart';
import 'bloc/easy_attachment_event.dart';
import 'bloc/easy_attachment_state.dart';
import 'easy_attachment_config.dart';
import 'easy_attachment_gallery_page.dart';
import 'easy_attachment_item.dart';
import 'easy_attachment_picker_sheet.dart';
import 'easy_attachment_upload_status.dart';
import 'easy_attachment_file_type.dart';

class EasyAttachmentGrid extends StatelessWidget {
  final bool editable;
  final EasyAttachmentConfig config;

  const EasyAttachmentGrid({
    super.key,
    this.editable = true,
    this.config = const EasyAttachmentConfig(),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = config.labels;

    return BlocBuilder<EasyAttachmentBloc, EasyAttachmentState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labels.headerTitle(state.items.length),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (state.isUploading)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(
                  value:
                      state.uploadProgress > 0 ? state.uploadProgress : null,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  labels.uploadErrorMessage(state.error!),
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (editable && state.items.isEmpty)
              _EasyAddTile(
                size: config.tileSize,
                borderRadius: config.tileBorderRadius,
                expanded: true,
                label: labels.addButtonLabel,
                onTap: () => _showPickerSheet(context),
              )
            else
              SizedBox(
                height: config.tileSize,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: editable
                      ? state.items.length + 1
                      : state.items.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: config.tileSpacing),
                  itemBuilder: (context, index) {
                    if (editable && index == 0) {
                      return _EasyAddTile(
                        size: config.tileSize,
                        borderRadius: config.tileBorderRadius,
                        label: labels.addButtonLabel,
                        onTap: () => _showPickerSheet(context),
                      );
                    }

                    final itemIndex = editable ? index - 1 : index;
                    final item = state.items[itemIndex];

                    return _EasyAttachmentTile(
                      item: item,
                      size: config.tileSize,
                      borderRadius: config.tileBorderRadius,
                      editable: editable,
                      onTap: () => _openPreview(context, item),
                      onLongPress: () => _showContextMenu(context, item),
                      onDelete: () =>
                          _confirmDelete(context, item.localId),
                      onRetry: () => context
                          .read<EasyAttachmentBloc>()
                          .add(EasyRetryUpload(item.localId)),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _openPreview(BuildContext context, EasyAttachmentItem item) {
    if (!item.isImage) return;

    final bloc = context.read<EasyAttachmentBloc>();
    final allImages = bloc.state.items.where((i) => i.isImage).toList();
    final initialIndex =
        allImages.indexWhere((i) => i.localId == item.localId);
    if (initialIndex < 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EasyAttachmentGalleryPage(
          images: allImages,
          initialIndex: initialIndex,
          editable: editable,
          config: config,
          onDelete: (localId) {
            bloc.add(EasyRemoveAttachment(localId));
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String localId) {
    final bloc = context.read<EasyAttachmentBloc>();
    final labels = config.labels;

    void doDelete() => bloc.add(EasyRemoveAttachment(localId));

    if (config.onDeleteConfirm != null) {
      config.onDeleteConfirm!(context, doDelete);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(labels.deleteConfirmTitle),
          content: Text(labels.deleteConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(labels.deleteCancelButton),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                doDelete();
              },
              child: Text(labels.deleteConfirmButton),
            ),
          ],
        ),
      );
    }
  }

  void _showContextMenu(BuildContext context, EasyAttachmentItem item) {
    final theme = Theme.of(context);
    final labels = config.labels;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EasyBottomSheetWidgets.handle(theme),
              EasyBottomSheetWidgets.title(theme, item.fileName),
              const SizedBox(height: 4),
              Text(
                item.formattedSize,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),
              EasyBottomSheetWidgets.divider(theme),
              const SizedBox(height: 4),
              if (item.isImage)
                EasyBottomSheetWidgets.menuItem(
                  theme: theme,
                  icon: Icons.visibility,
                  title: labels.previewTitle,
                  subtitle: labels.previewSubtitle,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openPreview(context, item);
                  },
                ),
              if (config.onShare != null)
                EasyBottomSheetWidgets.menuItem(
                  theme: theme,
                  icon: Icons.share,
                  title: labels.shareTitle,
                  subtitle: labels.shareSubtitle,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareFile(item);
                  },
                ),
              if (editable)
                EasyBottomSheetWidgets.menuItem(
                  theme: theme,
                  icon: Icons.delete_outline,
                  title: labels.deleteTitle,
                  subtitle: labels.deleteSubtitle,
                  color: theme.colorScheme.error,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDelete(context, item.localId);
                  },
                ),
              const SizedBox(height: 4),
              EasyBottomSheetWidgets.divider(theme),
              const SizedBox(height: 4),
              EasyBottomSheetWidgets.cancelButton(theme, sheetContext,
                  label: labels.cancelLabel),
            ],
          ),
        ),
      ),
    );
  }

  void _shareFile(EasyAttachmentItem item) {
    final path = item.localPath;
    if (path == null) return;
    config.onShare?.call(path);
  }

  void _showPickerSheet(BuildContext context) {
    final bloc = context.read<EasyAttachmentBloc>();
    showModalBottomSheet(
      context: context,
      builder: (_) => EasyAttachmentPickerSheet(
        config: config,
        onFilePicked: (file) {
          bloc.add(EasyAddAttachment(file));
        },
      ),
    );
  }
}

class _EasyAddTile extends StatefulWidget {
  final double size;
  final double borderRadius;
  final bool expanded;
  final String label;
  final VoidCallback onTap;

  const _EasyAddTile({
    required this.size,
    required this.borderRadius,
    this.expanded = false,
    required this.label,
    required this.onTap,
  });

  @override
  State<_EasyAddTile> createState() => _EasyAddTileState();
}

class _EasyAddTileState extends State<_EasyAddTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = widget.expanded
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: theme.colorScheme.primary, size: 28),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Container(
          width: widget.expanded ? double.infinity : widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _EasyAttachmentTile extends StatefulWidget {
  final EasyAttachmentItem item;
  final double size;
  final double borderRadius;
  final bool editable;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  const _EasyAttachmentTile({
    required this.item,
    required this.size,
    required this.borderRadius,
    required this.editable,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onRetry,
  });

  @override
  State<_EasyAttachmentTile> createState() => _EasyAttachmentTileState();
}

class _EasyAttachmentTileState extends State<_EasyAttachmentTile> {
  bool _tapDown = false;
  bool _longPressed = false;

  double get _scale => _longPressed ? 0.88 : (_tapDown ? 0.95 : 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _tapDown = true),
      onTapUp: (_) => setState(() => _tapDown = false),
      onTapCancel: () => setState(() => _tapDown = false),
      onTap: widget.onTap,
      onLongPressStart: (_) => setState(() {
        _tapDown = false;
        _longPressed = true;
      }),
      onLongPressEnd: (_) {
        setState(() => _longPressed = false);
        widget.onLongPress();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: theme.colorScheme.surface,
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildContent(theme),
                if (widget.item.status == EasyUploadStatus.uploading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (widget.item.status == EasyUploadStatus.error)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: widget.onRetry,
                      ),
                    ),
                  ),
                if (widget.editable &&
                    widget.item.status != EasyUploadStatus.uploading)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                if (!widget.item.isImage)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Text(
                        widget.item.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.item.isImage && widget.item.localPath != null) {
      return Image.file(
        File(widget.item.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildIconPlaceholder(theme),
      );
    }

    return _buildIconPlaceholder(theme);
  }

  Widget _buildIconPlaceholder(ThemeData theme) {
    final iconData = switch (widget.item.type) {
      EasyAttachmentFileType.pdf => Icons.picture_as_pdf,
      EasyAttachmentFileType.doc => Icons.description,
      EasyAttachmentFileType.image => Icons.image,
      EasyAttachmentFileType.other => Icons.insert_drive_file,
    };

    final iconColor = switch (widget.item.type) {
      EasyAttachmentFileType.pdf => Colors.red,
      EasyAttachmentFileType.doc => Colors.blue,
      EasyAttachmentFileType.image => Colors.green,
      EasyAttachmentFileType.other => Colors.grey,
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(iconData, color: iconColor, size: 32),
        const SizedBox(height: 2),
        Text(
          widget.item.formattedSize,
          style: TextStyle(
            color: theme.colorScheme.secondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
