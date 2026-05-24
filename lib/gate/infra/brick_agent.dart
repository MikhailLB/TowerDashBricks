import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../config/endpoint_vault.dart';

String _androidUserAgent({
  required int sdk,
  required String brand,
  required String model,
  required String build,
}) =>
    'Mozilla/5.0 (Linux; Android $sdk; $brand $model Build/$build) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/${uaChromeBuild()} Mobile Safari/537.36';

String _iosUserAgent(String ver) {
  final dotless = ver.replaceAll('.', '_');
  return 'Mozilla/5.0 (iPhone; CPU iPhone OS $dotless like Mac OS X) '
      'AppleWebKit/${uaSafariBuild()} (KHTML, like Gecko) '
      'Version/$ver Mobile/15E148 Safari/${uaSafariBuild()}';
}

String _defaultUserAgent() => Platform.isAndroid
    ? _androidUserAgent(sdk: 14, brand: 'Samsung', model: 'Galaxy S24', build: 'TP1A.220624.014')
    : _iosUserAgent('17.5');

/// HTTP client that injects a realistic mobile-browser User-Agent on every
/// outbound request. Built from actual device info so it varies per device.
class BrickAgent extends http.BaseClient {
  final http.Client _http = http.Client();
  String _ua = '';

  Future<void> warmup() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final d = await info.androidInfo;
        final tag = d.display.isNotEmpty ? d.display : d.id;
        _ua = _androidUserAgent(
          sdk: d.version.sdkInt,
          brand: d.brand,
          model: d.model,
          build: tag,
        );
      } else if (Platform.isIOS) {
        final d = await info.iosInfo;
        _ua = _iosUserAgent(d.systemVersion);
      } else {
        _ua = _defaultUserAgent();
      }
    } catch (_) {
      _ua = _defaultUserAgent();
    }
  }

  String get userAgent => _ua.isNotEmpty ? _ua : _defaultUserAgent();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!request.headers.containsKey('User-Agent') &&
        !request.headers.containsKey('user-agent')) {
      request.headers['User-Agent'] = userAgent;
    }
    return _http.send(request);
  }

  @override
  void close() => _http.close();
}

final brickAgent = BrickAgent();
