import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/easy_bottom_sheet_widgets.dart';
import 'easy_attachment_config.dart';

class EasyAttachmentPickerSheet extends StatelessWidget {
  final void Function(File file) onFilePicked;
  final EasyAttachmentConfig config;

  const EasyAttachmentPickerSheet({
    super.key,
    required this.onFilePicked,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = config.labels;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EasyBottomSheetWidgets.handle(theme),
            EasyBottomSheetWidgets.title(theme, labels.pickerTitle),
            const SizedBox(height: 12),
            EasyBottomSheetWidgets.divider(theme),
            const SizedBox(height: 4),
            if (config.onPickFromGallery != null)
              EasyBottomSheetWidgets.menuItem(
                theme: theme,
                icon: Icons.photo_library,
                title: labels.pickFromGalleryTitle,
                subtitle: labels.pickFromGallerySubtitle,
                onTap: () async {
                  Navigator.pop(context);
                  final file = await config.onPickFromGallery!(context);
                  if (file != null) onFilePicked(file);
                },
              ),
            if (config.onPickFromCamera != null)
              EasyBottomSheetWidgets.menuItem(
                theme: theme,
                icon: Icons.camera_alt,
                title: labels.pickFromCameraTitle,
                subtitle: labels.pickFromCameraSubtitle,
                onTap: () async {
                  Navigator.pop(context);
                  final file = await config.onPickFromCamera!(context);
                  if (file != null) onFilePicked(file);
                },
              ),
            if (config.enableDocumentPicker && config.onPickDocument != null)
              EasyBottomSheetWidgets.menuItem(
                theme: theme,
                icon: Icons.attach_file,
                title: labels.pickDocumentTitle,
                subtitle: labels.pickDocumentSubtitle,
                onTap: () async {
                  Navigator.pop(context);
                  final file = await config.onPickDocument!(context);
                  if (file != null) onFilePicked(file);
                },
              ),
            const SizedBox(height: 4),
            EasyBottomSheetWidgets.divider(theme),
            const SizedBox(height: 4),
            EasyBottomSheetWidgets.cancelButton(theme, context,
                label: labels.cancelLabel),
          ],
        ),
      ),
    );
  }
}
