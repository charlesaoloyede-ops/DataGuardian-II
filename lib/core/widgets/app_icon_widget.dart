import 'dart:convert';
import 'package:flutter/material.dart';

/// Renders an app icon from base64-encoded PNG, or an Android fallback.
class AppIconWidget extends StatelessWidget {
  final String? iconBase64;
  final double size;
  const AppIconWidget({super.key, this.iconBase64, this.size = 40});

  @override
  Widget build(BuildContext context) {
    if (iconBase64 != null) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(iconBase64!),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.android_rounded,
        size: size * 0.55,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
