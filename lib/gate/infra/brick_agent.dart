import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../config/endpoint_vault.dart';

String _buildAndroidUa({
  required int sdk,
  required String brand,
  required String model,
  required String build,
}) =>
    'Mozilla/5.0 (Linux; Android $sdk; $brand $model Build/$build) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/${uaChromeBuild()} Mobile Safari/537.36';

String _buildIosUa(String ver) {
  final dotless = ver.replaceAll('.', '_');
  return 'Mozilla/5.0 (iPhone; CPU iPhone OS $dotless like Mac OS X) '
      'AppleWebKit/${uaSafariBuild()} (KHTML, like Gecko) '
      'Version/$ver Mobile/15E148 Safari/${uaSafariBuild()}';
}

String _fallbackUa() => Platform.isAndroid
    ? _buildAndroidUa(sdk: 14, brand: 'Samsung', model: 'Galaxy S24', build: 'TP1A.220624.014')
    : _buildIosUa('17.5');

/// HTTP client that injects a realistic mobile-browser User-Agent on every
/// outbound request. UA is built from actual device info so it varies per device.
class BrickAgent extends http.BaseClient {
  final http.Client _inner = http.Client();
  String _ua = '';

  Future<void> warmup() async {
    try {
      final probe = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await probe.androidInfo;
        final tag = info.display.isNotEmpty ? info.display : info.id;
        _ua = _buildAndroidUa(
          sdk: info.version.sdkInt,
          brand: info.brand,
          model: info.model,
          build: tag,
        );
      } else if (Platform.isIOS) {
        final info = await probe.iosInfo;
        _ua = _buildIosUa(info.systemVersion);
      } else {
        _ua = _fallbackUa();
      }
    } catch (_) {
      _ua = _fallbackUa();
    }
  }

  String get userAgent => _ua.isNotEmpty ? _ua : _fallbackUa();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!request.headers.containsKey('User-Agent') &&
        !request.headers.containsKey('user-agent')) {
      request.headers['User-Agent'] = userAgent;
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final brickAgent = BrickAgent();
