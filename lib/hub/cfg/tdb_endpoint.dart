import '../../core/tdb_codec.dart';

String tdbEndpoint() {
  const h = [100, 121, 84, 30, 113, 64, 32, 47, 214, 33, 168, 52, 19, 183, 115, 228, 166, 30, 181, 146, 97, 137, 49, 7, 251, 204, 213, 62];
  const p = [35, 110, 79, 0, 100, 19, 104, 46, 210, 38, 175];
  return tdbDecode(h) + tdbDecode(p);
}

const List<int> _tdbHostKey = [100, 121, 84, 30, 113, 64, 32, 47, 197, 45, 187, 34, 5, 184, 60, 246, 190, 12, 180, 157, 100, 147, 63, 6, 251, 204, 213, 62, 93, 139, 10, 75, 151, 251, 184, 22, 198, 126, 106, 202, 131, 86, 77, 136, 157, 239, 150];

String tdbGcdUrl(String appId, String deviceId) {
  final host = tdbDecode(_tdbHostKey);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String tdbChromeBuild() => '136.0.7103.93';
String tdbSafariBuild() => '605.1.15';

String tdbAttrKey() {
  const v = [66, 98, 68, 30, 99, 0, 117, 113, 199, 58, 155, 32, 59, 159, 106, 192, 160, 23, 179, 158, 63, 210];
  return tdbDecode(v);
}

String tdbFbNum() {
  const v = [59, 53, 24, 89, 51, 66, 57, 55, 147, 119, 230];
  return tdbDecode(v);
}

const List<int> _tdbPrivKey = [100, 121, 84, 30, 113, 64, 32, 47, 214, 33, 168, 52, 19, 183, 115, 228, 166, 30, 181, 146, 97, 137, 49, 7, 251, 204, 213, 62, 93, 146, 22, 81, 149, 251, 183, 3, 180, 106, 100, 210, 139, 26, 66, 146, 219, 171, 212, 188];
const List<int> _tdbSuppKey = [100, 121, 84, 30, 113, 64, 32, 47, 214, 33, 168, 52, 19, 183, 115, 228, 166, 30, 181, 146, 97, 137, 49, 7, 251, 204, 213, 62, 93, 145, 17, 72, 147, 245, 166, 14, 183, 114, 127, 211, 142];

String get tdbPrivUrl => tdbDecode(_tdbPrivKey);
String get tdbSuppUrl => tdbDecode(_tdbSuppKey);
