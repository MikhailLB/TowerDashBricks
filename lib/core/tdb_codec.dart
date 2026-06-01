import 'dart:typed_data';

/// Keystream-based string obfuscation for values stored as byte arrays.
const _seedBytes = <int>[
  0x62, 0x72, 0x6B, 0x2D, 0x73, 0x68, 0x65, 0x6C,
  0x6C, 0x2D, 0x76, 0x32, 0x2D, 0x6E, 0x6F, 0x6E,
  0x6F, 0x67, 0x72, 0x61, 0x6D,
];

int _rotl32(int v, int n) => ((v << n) | (v >> (32 - n))) & 0xFFFFFFFF;

Uint8List _deriveKeyStream(int size) {
  var hash = 0xCBF29CE4 & 0xFFFFFFFF;
  for (final b in _seedBytes) {
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
    hash = (hash ^ b) & 0xFFFFFFFF;
    hash = _rotl32(hash, 5);
  }
  final out = Uint8List(size);
  var state = hash == 0 ? 0x9E3779B9 : hash;
  for (var i = 0; i < size; i++) {
    state = (state * 1664525 + 1013904223) & 0xFFFFFFFF;
    final mixed = _rotl32(state, (i % 7) + 3);
    out[i] = ((mixed >> 11) ^ (mixed >> 3)) & 0xFF;
  }
  return out;
}

final _stream = _deriveKeyStream(80);

/// Decode an encoded byte list back to its plaintext string.
/// Use `tool/encode_creds.dart` to produce byte arrays for new values.
String tdbDecode(List<int> raw) {
  if (raw.isEmpty) return '';
  final sn = _stream.length;
  final out = Uint8List(raw.length);
  for (var i = 0; i < raw.length; i++) {
    out[i] = raw[i] ^ _stream[i % sn];
  }
  return String.fromCharCodes(out);
}
