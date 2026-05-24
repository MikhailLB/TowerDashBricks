// ignore_for_file: avoid_print
import 'dart:typed_data';

// XOR cipher seed — MUST match mask_util.dart in lib/core/
const _seedBytes = <int>[
  0x74, 0x6F, 0x77, 0x65, 0x72, 0x2E, 0x64, 0x61,
  0x73, 0x68, 0x2E, 0x62, 0x72, 0x69, 0x63, 0x6B,
  0x73, 0x2E, 0x67, 0x61, 0x74, 0x65,
]; // "tower.dash.bricks.gate"

Uint8List _deriveKeyStream(int size) {
  var hash = 0x811C9DC5;
  for (final b in _seedBytes) {
    hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
  }
  final out = Uint8List(size);
  var state = hash == 0 ? 0xDEADBEEF : hash;
  for (var i = 0; i < size; i++) {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    out[i] = (state >> 7) & 0xFF;
  }
  return out;
}

final _stream = _deriveKeyStream(64);

List<int> encode(String s) {
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    out.add(s.codeUnitAt(i) ^ _stream[i % _stream.length]);
  }
  return out;
}

String decode(List<int> v) {
  final out = <int>[];
  final sn = _stream.length;
  for (var i = 0; i < v.length; i++) {
    out.add(v[i] ^ _stream[i % sn]);
  }
  return String.fromCharCodes(out);
}

String fmt(List<int> v) => '[${v.join(', ')}]';

void main() {
  const configHost   = 'https://towerdashbriicks.com';
  const configPath   = '/config.php';
  const privacyUrl   = 'https://towerdashbriicks.com/privacy-policy.html';
  const supportUrl   = 'https://towerdashbriicks.com/support.html';
  const gcdHost      = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';
  const afKey        = 'NodpazzqetDqZLxWnkte78';
  const fbNumber     = '78871867199';

  final hostBytes    = encode(configHost);
  final pathBytes    = encode(configPath);
  final privBytes    = encode(privacyUrl);
  final suppBytes    = encode(supportUrl);
  final gcdBytes     = encode(gcdHost);
  final afBytes      = encode(afKey);
  final fbBytes      = encode(fbNumber);

  print('═══ BYTE ARRAYS ═══');
  print('HOST : ${fmt(hostBytes)}');
  print('PATH : ${fmt(pathBytes)}');
  print('PRIV : ${fmt(privBytes)}');
  print('SUPP : ${fmt(suppBytes)}');
  print('GCD  : ${fmt(gcdBytes)}');
  print('AF   : ${fmt(afBytes)}');
  print('FB   : ${fmt(fbBytes)}');

  print('');
  print('═══ VERIFY (should match originals exactly) ═══');
  print('configHost  : ${decode(hostBytes)}');
  print('configPath  : ${decode(pathBytes)}');
  print('privacyUrl  : ${decode(privBytes)}');
  print('supportUrl  : ${decode(suppBytes)}');
  print('gcdHost     : ${decode(gcdBytes)}');
  print('afKey       : ${decode(afBytes)}');
  print('fbNumber    : ${decode(fbBytes)}');
}
