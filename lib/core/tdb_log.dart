import 'package:flutter/foundation.dart';

/// Debug-only logger. In release builds `kDebugMode` is a compile-time
/// `false`, so both the call and the (possibly sensitive) message string are
/// removed by tree-shaking and never reach the shipped binary or device logs.
void tdbLog(Object? message) {
  if (kDebugMode) {
    debugPrint('$message');
  }
}
