import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/v2board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('V2boardApiClient', () {
    test('logs in with object auth data and returns a Clash URL', () async {
      final adapter = _QueueAdapter([
        _jsonResponse({
          'data': {'auth_data': 'session-token'},
        }),
        _jsonResponse({
          'data': {
            'subscribe_url':
                'https://subscribe.example/api/v1/client/subscribe?token=abc',
          },
        }),
      ]);
      final client = V2boardApiClient(dio: Dio()..httpClientAdapter = adapter);

      final session = await client.login(
        baseUrl: 'panel.example',
        email: 'user@example.com',
        password: 'password',
      );

      expect(session.baseUrl, 'https://panel.example/');
      expect(session.authData, 'session-token');
      expect(session.subscriptionUrl, contains('flag=clash'));
      expect(adapter.requests.last.headers['Authorization'], 'session-token');
    });

    test('supports legacy string auth data and Clash URL', () async {
      final adapter = _QueueAdapter([
        _jsonResponse({'data': 'legacy-token'}),
        _jsonResponse({
          'data': {
            'subscribe_url_clash':
                'https://subscribe.example/client?token=abc&flag=clash',
          },
        }),
      ]);
      final client = V2boardApiClient(dio: Dio()..httpClientAdapter = adapter);

      final session = await client.login(
        baseUrl: 'https://panel.example/base',
        email: 'user@example.com',
        password: 'password',
      );

      expect(session.authData, 'legacy-token');
      expect(
        session.subscriptionUrl,
        'https://subscribe.example/client?token=abc&flag=clash',
      );
    });

    test('surfaces the V2Board error message', () async {
      final adapter = _QueueAdapter([
        _jsonResponse({'message': 'Incorrect email or password'}, 500),
      ]);
      final client = V2boardApiClient(dio: Dio()..httpClientAdapter = adapter);

      await expectLater(
        client.login(
          baseUrl: 'https://panel.example',
          email: 'user@example.com',
          password: 'bad-password',
        ),
        throwsA(
          isA<V2boardException>().having(
            (error) => error.message,
            'message',
            'Incorrect email or password',
          ),
        ),
      );
    });
  });
}

ResponseBody _jsonResponse(Object value, [int statusCode = 200]) {
  return ResponseBody.fromString(
    jsonEncode(value),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

final class _QueueAdapter implements HttpClientAdapter {
  final List<ResponseBody> _responses;
  final List<RequestOptions> requests = [];

  _QueueAdapter(this._responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _responses.removeAt(0);
  }

  @override
  void close({bool force = false}) {}
}
