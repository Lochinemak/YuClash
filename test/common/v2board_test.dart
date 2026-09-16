import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/v2board.dart';
import 'package:fl_clash/models/v2board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('V2boardApiClient', () {
    test(
      'logs in with object auth data and returns a Clash Meta URL',
      () async {
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
        final client = V2boardApiClient(
          dio: Dio()..httpClientAdapter = adapter,
        );

        final session = await client.login(
          baseUrl: 'panel.example',
          email: 'user@example.com',
          password: 'password',
        );

        expect(session.baseUrl, 'https://panel.example/');
        expect(session.authData, 'session-token');
        expect(session.subscriptionUrl, contains('flag=clashmeta'));
        expect(adapter.requests.last.headers['Authorization'], 'session-token');
      },
    );

    test('supports legacy string auth data and Clash Meta URL', () async {
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
        'https://subscribe.example/client?token=abc&flag=clashmeta',
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

    test('reads the complete account and subscription overview', () async {
      final adapter = _QueueAdapter([
        _jsonResponse({
          'data': {
            'subscribe_url':
                'https://subscribe.example/client?token=account-token',
            'email': 'account@example.com',
            'u': 1024,
            'd': 2048,
            'transfer_enable': 8192,
            'expired_at': 1900000000,
            'alive_ip': 2,
            'device_limit': 5,
            'plan': {'name': 'Premium'},
          },
        }),
      ]);
      final client = V2boardApiClient(dio: Dio()..httpClientAdapter = adapter);

      final snapshot = await client.getSubscriptionSnapshot(
        baseUrl: 'https://panel.example/',
        authData: 'session-token',
      );

      expect(snapshot.subscriptionUrl, contains('flag=clashmeta'));
      expect(snapshot.accountOverview.email, 'account@example.com');
      expect(snapshot.accountOverview.planName, 'Premium');
      expect(snapshot.accountOverview.upload, 1024);
      expect(snapshot.accountOverview.download, 2048);
      expect(snapshot.accountOverview.total, 8192);
      expect(snapshot.accountOverview.expire, 1900000000);
      expect(snapshot.accountOverview.onlineDevices, 2);
      expect(snapshot.accountOverview.deviceLimit, 5);
      expect(snapshot.accountOverview.avatarUrl, contains('cravatar.cn'));
    });

    test('accepts missing optional subscription fields', () async {
      final adapter = _QueueAdapter([
        _jsonResponse({
          'data': {
            'subscribe_url': 'https://subscribe.example/client?token=abc',
          },
        }),
      ]);
      final client = V2boardApiClient(dio: Dio()..httpClientAdapter = adapter);

      final snapshot = await client.getSubscriptionSnapshot(
        baseUrl: 'https://panel.example/',
        authData: 'session-token',
        fallbackEmail: 'fallback@example.com',
      );

      expect(snapshot.accountOverview.email, 'fallback@example.com');
      expect(snapshot.accountOverview.planName, null);
      expect(snapshot.accountOverview.total, 0);
      expect(snapshot.accountOverview.expire, null);
      expect(snapshot.accountOverview.deviceLimit, null);
    });
  });

  test('loads legacy sessions without a cached account overview', () {
    final session = V2boardSession.fromJson({
      'baseUrl': 'https://panel.example/',
      'email': 'legacy@example.com',
      'authData': 'legacy-token',
      'subscriptionUrl': 'https://subscribe.example/client?token=abc',
    });

    expect(session.accountOverview, null);
    expect(session.email, 'legacy@example.com');
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
