import 'package:flutter/foundation.dart';

bool get isLinuxDesktop =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

bool get shouldShowTerminalKeyboardBar =>
    !kIsWeb && shouldShowTerminalKeyboardBarFor(defaultTargetPlatform);

bool shouldShowTerminalKeyboardBarFor(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => false,
  };
}
