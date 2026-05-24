import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/brick_config.dart';
import '../models/brick_reply.dart';
import 'brick_agent.dart';
import 'brick_vault.dart';

/// Posts an install/launch payload to the remote gate endpoint and
/// caches the returned destination URL.
class BrickDispatch {
  final BrickVault _vault;

  BrickDispatch(this._vault);

  Future<BrickReply> send(Map<String, dynamic> body) async {
    final endpoint = BrickConfig.configEndpoint;
    debugPrint('[TDB.BD] send → endpoint="$endpoint"');
    if (endpoint.isEmpty) {
      debugPrint('[TDB.BD] endpoint not configured — declined');
      return BrickReply.declined('endpoint_missing');
    }
    try {
      final uri = Uri.parse(endpoint);
      debugPrint('[TDB.BD] POST $uri  body=${jsonEncode(body)}');
      final resp = await brickAgent
          .post(uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      debugPrint('[TDB.BD] HTTP ${resp.statusCode}');
      final preview = resp.body.length > 500
          ? '${resp.body.substring(0, 500)}…'
          : resp.body;
      debugPrint('[TDB.BD] body=$preview');

      if (resp.statusCode != 200) {
        return BrickReply.declined('http_${resp.statusCode}');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        return BrickReply.declined('bad_json');
      }
      final reply = BrickReply.fromMap(decoded);
      debugPrint('[TDB.BD] reply granted=${reply.granted} dest=${reply.destination}');
      if (reply.granted && reply.destination != null) {
        await _vault.writeSavedUrl(reply.destination!);
        if (reply.expiresAt != null) {
          await _vault.writeSavedTtl(reply.expiresAt!);
        }
      }
      return reply;
    } catch (err, st) {
      debugPrint('[TDB.BD] error: $err\n$st');
      return BrickReply.declined(err.toString());
    }
  }
}
