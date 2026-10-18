import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:handtech/services/nolan_chat_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends the message and chat history without authentication', () async {
    late http.Request request;
    final client = MockClient((incoming) async {
      request = incoming;
      return http.Response(jsonEncode({'reply': 'Bonjour !'}), 200);
    });
    final service = NolanChatService(client: client);
    addTearDown(service.dispose);

    final reply = await service.sendMessage(
      message: ' Bonjour ',
      history: const [
        NolanChatMessage(role: 'user', content: 'Salut'),
        NolanChatMessage(role: 'assistant', content: 'Bonjour'),
      ],
    );

    expect(reply, 'Bonjour !');
    expect(request.url.path, '/api/chat');
    expect(request.headers['authorization'], isNull);
    expect(jsonDecode(request.body), {
      'message': 'Bonjour',
      'history': [
        {'role': 'user', 'content': 'Salut'},
        {'role': 'assistant', 'content': 'Bonjour'},
      ],
    });
  });

  test('surfaces server errors', () async {
    final client = MockClient(
      (_) async =>
          http.Response(jsonEncode({'detail': 'Service indisponible'}), 503),
    );
    final service = NolanChatService(client: client);
    addTearDown(service.dispose);

    await expectLater(
      service.sendMessage(message: 'Bonjour', history: const []),
      throwsA(
        isA<NolanChatException>().having(
          (error) => error.message,
          'message',
          contains('HTTP 503: Service indisponible'),
        ),
      ),
    );
  });

  test('rejects requests outside the API size limits', () async {
    var requestCount = 0;
    final client = MockClient((_) async {
      requestCount++;
      return http.Response(jsonEncode({'reply': 'ok'}), 200);
    });
    final service = NolanChatService(client: client);
    addTearDown(service.dispose);

    await expectLater(
      service.sendMessage(message: 'x' * 4001, history: const []),
      throwsA(isA<NolanChatException>()),
    );
    await expectLater(
      service.sendMessage(
        message: 'Bonjour',
        history: List.generate(
          21,
          (index) => NolanChatMessage(role: 'user', content: '$index'),
        ),
      ),
      throwsA(isA<NolanChatException>()),
    );
    expect(requestCount, 0);
  });
}
