import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// HTTPS origin of the property backend, including the function path.
class PropertyApi {
  static const _base = String.fromEnvironment('PROPERTY_API_URL');

  static bool get isConfigured => _base.isNotEmpty;

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.tryParse('$_base/$path');
    if (url == null || url.scheme != 'https' || url.host.isEmpty) {
      throw StateError('Backend verifikasi kos belum dikonfigurasi.');
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Silakan login kembali.');
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw StateError(
        'Layanan verifikasi belum tersedia (${response.statusCode}).',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<String>> legacyIds() async {
    final ids = <String>[];
    String? cursor;
    do {
      final page = await _post('legacy', {'cursor': ?cursor});
      ids.addAll((page['ids'] as List).cast<String>());
      cursor = page['next'] as String?;
    } while (cursor != null);
    return ids;
  }
}
