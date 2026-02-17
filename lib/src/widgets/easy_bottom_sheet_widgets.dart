import 'package:flutter/material.dart';

/// Reusable bottom sheet building blocks.
class EasyBottomSheetWidgets {
  EasyBottomSheetWidgets._();

  static Widget handle(ThemeData theme) => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  static Widget title(ThemeData theme, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  static Widget divider(ThemeData theme) => Divider(
        height: 1,
        color: theme.colorScheme.secondary.withValues(alpha: 0.15),
      );

  static Widget menuItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? theme.colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: color != null ? TextStyle(color: color) : null,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: color?.withValues(alpha: 0.7) ?? theme.colorScheme.secondary,
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  static Widget cancelButton(
    ThemeData theme,
    BuildContext context, {
    String label = 'Cancel',
  }) =>
      ListTile(
        title: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => Navigator.pop(context),
      );
}
