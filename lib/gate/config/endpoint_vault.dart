import '../../core/mask_util.dart';

String gateEndpointUrl() {
  const h = [7, 88, 223, 60, 88, 102, 35, 160, 124, 160, 92, 228, 236, 90, 1, 233, 110, 130, 243, 186, 177, 13, 130, 215, 5, 124, 1, 105];
  const p = [64, 79, 196, 34, 77, 53, 107, 161, 120, 167, 91];
  return unmask(h) + unmask(p);
}

const List<int> _gcdHostMask = [7, 88, 223, 60, 88, 102, 35, 160, 111, 172, 79, 242, 250, 85, 78, 251, 118, 144, 242, 181, 180, 23, 140, 214, 5, 124, 1, 105, 183, 197, 6, 24, 66, 45, 220, 190, 194, 220, 252, 196, 135, 8, 126, 202, 135, 98, 103];

String gcdUrl(String appId, String deviceId) {
  final host = unmask(_gcdHostMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String uaChromeBuild() => '136.0.7103.93';
String uaSafariBuild() => '605.1.15';
