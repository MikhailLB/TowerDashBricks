import 'dart:convert';
import '../../core/tdb_log.dart';
import '../cfg/tdb_config.dart';
import '../data/tdb_reply.dart';
import 'tdb_http.dart';
import 'tdb_store.dart';

/// Posts an install/launch payload to the remote endpoint and caches the
/// returned destination URL.
class TdbRequest {
  final TdbStore _vault;

  TdbRequest(this._vault);

  Future<TdbReply> send(Map<String, dynamic> body) async {
    final endpoint = TdbConfig.configEndpoint;
    if (endpoint.isEmpty) {
      return TdbReply.declined('endpoint_missing');
    }
    try {
      final uri = Uri.parse(endpoint);
      final resp = await tdbHttp
          .post(uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      tdbLog('[req] status ${resp.statusCode}');

      if (resp.statusCode != 200) {
        return TdbReply.declined('http_${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return TdbReply.declined('bad_json');
      }
      final reply = TdbReply.fromMap(decoded);
      tdbLog('[req] granted=${reply.granted}');
      if (reply.granted && reply.destination != null) {
        await _vault.writeSavedUrl(reply.destination!);
        if (reply.expiresAt != null) {
          await _vault.writeSavedTtl(reply.expiresAt!);
        }
      }
      return reply;
    } catch (err) {
      tdbLog('[req] error');
      return TdbReply.declined(err.toString());
    }
  }
}
