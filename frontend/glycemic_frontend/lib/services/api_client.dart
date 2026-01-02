// lib/services/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/env_record.dart';

class ApiClient {
  ApiClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // Adjust baseUrl for device vs emulator
  final String baseUrl = 'http://localhost:4000';

  Future<List<EgvRecord>> fetchEgvs(String userId) async {
    final uri = Uri.parse('$baseUrl/api/dexcom/egvs?userId=$userId');

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load EGVs: ${res.statusCode} ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final egvsJson = body['egvs'] as List<dynamic>? ?? [];

    return egvsJson
        .map((e) => EgvRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
