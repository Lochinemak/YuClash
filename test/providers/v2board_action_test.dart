import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/v2board.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initialization keeps cached data and refreshes it in background',
    () async {
      final cached = _session(planName: 'Cached');
      final store = _MemorySessionStore(cached);
      final adapter = _QueueAdapter([_subscriptionResponse(planName: 'Fresh')]);
      final container = ProviderContainer(
        overrides: [
          v2boardSessionStoreProvider.overrideWithValue(store),
          v2boardApiClientProvider.overrideWithValue(
            V2boardApiClient(dio: Dio()..httpClientAdapter = adapter),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(v2boardActionProvider.notifier).initialize();
      expect(
        container
            .read(v2boardActionProvider)
            .session
            ?.accountOverview
            ?.planName,
        'Cached',
      );

      await pumpEventQueue(times: 20);

      expect(
        container
            .read(v2boardActionProvider)
            .session
            ?.accountOverview
            ?.planName,
        'Fresh',
      );
      expect(store.value?.accountOverview?.planName, 'Fresh');
    },
  );

  test('background refresh failure preserves the cached session', () async {
    final cached = _session(planName: 'Cached');
    final store = _MemorySessionStore(cached);
    final adapter = _QueueAdapter([
      _jsonResponse({'message': 'Service unavailable'}, 500),
    ]);
    final container = ProviderContainer(
      overrides: [
        v2boardSessionStoreProvider.overrideWithValue(store),
        v2boardApiClientProvider.overrideWithValue(
          V2boardApiClient(dio: Dio()..httpClientAdapter = adapter),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(v2boardActionProvider.notifier).initialize();
    await pumpEventQueue(times: 20);

    final state = container.read(v2boardActionProvider);
    expect(state.session?.accountOverview?.planName, 'Cached');
    expect(state.error, isA<V2boardException>());
  });

  test(
    'manual refresh imports the subscription and logout clears it',
    () async {
      final store = _MemorySessionStore(_session(planName: 'Cached'));
      final adapter = _QueueAdapter([
        _subscriptionResponse(planName: 'Background'),
        _subscriptionResponse(planName: 'Manual'),
      ]);
      late _RecordingProfilesAction profilesAction;
      final container = ProviderContainer(
        overrides: [
          v2boardSessionStoreProvider.overrideWithValue(store),
          v2boardApiClientProvider.overrideWithValue(
            V2boardApiClient(dio: Dio()..httpClientAdapter = adapter),
          ),
          profilesActionProvider.overrideWith(() {
            profilesAction = _RecordingProfilesAction();
            return profilesAction;
          }),
        ],
      );
      addTearDown(container.dispose);
      final action = container.read(v2boardActionProvider.notifier);

      await action.initialize();
      await pumpEventQueue(times: 20);
      await action.refreshSubscription();

      expect(profilesAction.importedUrl, contains('flag=clashmeta'));
      expect(
        container
            .read(v2boardActionProvider)
            .session
            ?.accountOverview
            ?.planName,
        'Manual',
      );

      await action.logout();
      expect(container.read(v2boardActionProvider).session, null);
      expect(store.value, null);
    },
  );
}

V2boardSession _session({required String planName}) {
  return V2boardSession(
    baseUrl: 'https://panel.example/',
    email: 'user@example.com',
    authData: 'session-token',
    subscriptionUrl: 'https://subscribe.example/client?token=abc',
    accountOverview: V2boardAccountOverview(
      email: 'user@example.com',
      avatarUrl: '',
      planName: planName,
      upload: 1,
      download: 2,
      total: 10,
      expire: null,
      onlineDevices: 1,
      deviceLimit: null,
    ),
  );
}

ResponseBody _subscriptionResponse({required String planName}) {
  return _jsonResponse({
    'data': {
      'subscribe_url': 'https://subscribe.example/client?token=abc',
      'email': 'user@example.com',
      'u': 3,
      'd': 4,
      'transfer_enable': 20,
      'alive_ip': 2,
      'plan': {'name': planName},
    },
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

class _MemorySessionStore extends V2boardSessionStore {
  V2boardSession? value;

  _MemorySessionStore(this.value);

  @override
  Future<V2boardSession?> load() async => value;

  @override
  Future<void> save(V2boardSession session) async {
    value = session;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class _RecordingProfilesAction extends ProfilesAction {
  String? importedUrl;

  @override
  Future<Profile> importUrlProfile(String url, {String? label}) async {
    importedUrl = url;
    return Profile.normal(label: label, url: url);
  }
}

final class _QueueAdapter implements HttpClientAdapter {
  final List<ResponseBody> _responses;

  _QueueAdapter(this._responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _responses.removeAt(0);
  }

  @override
  void close({bool force = false}) {}
}
