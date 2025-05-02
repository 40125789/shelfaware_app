

import 'package:flutter/material.dart';

class SystemThemeObserver extends WidgetsBindingObserver {
  final VoidCallback onSystemThemeChanged;

  SystemThemeObserver({required this.onSystemThemeChanged});

  @override
  void didChangePlatformBrightness() {
    // Call the callback when the system theme changes
    onSystemThemeChanged();
  }
}
