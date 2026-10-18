import 'dart:convert';

import 'package:http/http.dart' as http;

class NolanChatMessage {
  const NolanChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class NolanChatException implements Exception {
  const NolanChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NolanChatService {
  NolanChatService({http.Client? client})
    : _client = client ?? http.Client();

  static final _endpoint = Uri.parse('https://nolan-a89w.onrender.com/api/chat');

  final http.Client _client;

  Future<String> sendMessage({
    required String message,
    required List<NolanChatMessage> history,
  }) async {
    final text = message.trim();
    if (text.isEmpty || text.length > 4000) {
      throw const NolanChatException(
        'Message must contain between 1 and 4000 characters.',
      );
    }
    if (history.length > 20) {
      throw const NolanChatException('Chat history cannot exceed 20 messages.');
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': text,
              'history': history.map((item) => item.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on Exception catch (error) {
      throw NolanChatException('Unable to reach Nolan: $error');
    }

    final Object? payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw NolanChatException(
        'Nolan returned an invalid response (HTTP ${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NolanChatException(
        'Nolan returned HTTP ${response.statusCode}: ${_errorDetail(payload)}',
      );
    }
    if (payload is! Map<String, dynamic> ||
        payload['reply'] is! String ||
        (payload['reply'] as String).trim().isEmpty) {
      throw const NolanChatException(
        'Nolan response does not contain a reply.',
      );
    }
    return (payload['reply'] as String).trim();
  }

  String _errorDetail(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final detail = payload['detail'] ?? payload['error'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      if (detail is List) return detail.join(', ');
    }
    return 'Please try again.';
  }

  void dispose() => _client.close();
}
