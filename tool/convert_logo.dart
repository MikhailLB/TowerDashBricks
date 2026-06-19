import 'dart:io';

import 'package:image/image.dart' as img;

/// Converts tdb_icon.webp → tdb_icon.png for flutter_launcher_icons.
void main() {
  final webpBytes = File('assets/tdb_icon.webp').readAsBytesSync();
  final decoded = img.decodeImage(webpBytes);
  if (decoded == null) {
    print('Failed to decode tdb_icon.webp');
    exit(1);
  }
  final outPath = 'assets/tdb_icon.png';
  File(outPath).writeAsBytesSync(img.encodePng(decoded));
  print('Wrote $outPath');
}
