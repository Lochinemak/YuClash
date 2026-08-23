part of '../action.dart';

@Riverpod(keepAlive: true)
class V2boardAction extends _$V2boardAction {
  @override
  V2boardAccountState build() {
    return const V2boardAccountState();
  }

  Future<void> initialize() async {
    if (state.initialized || state.loading) {
      return;
    }
    state = const V2boardAccountState(loading: true);
    final session = await v2boardSessionStore.load();
    state = V2boardAccountState(initialized: true, session: session);
  }

  Future<void> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    state = const V2boardAccountState(initialized: true, loading: true);
    try {
      final session = await v2boardApiClient.login(
        baseUrl: baseUrl,
        email: email,
        password: password,
      );
      await _importSubscription(session.subscriptionUrl);
      await v2boardSessionStore.save(session);
      state = V2boardAccountState(initialized: true, session: session);
    } catch (error, stackTrace) {
      state = V2boardAccountState(initialized: true, error: error);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> refreshSubscription() async {
    final session = state.session;
    if (session == null) {
      return;
    }
    state = V2boardAccountState(
      initialized: true,
      loading: true,
      session: session,
    );
    try {
      final subscriptionUrl = await v2boardApiClient.getSubscriptionUrl(
        baseUrl: session.baseUrl,
        authData: session.authData,
      );
      await _importSubscription(subscriptionUrl);
      final nextSession = session.copyWith(subscriptionUrl: subscriptionUrl);
      await v2boardSessionStore.save(nextSession);
      state = V2boardAccountState(initialized: true, session: nextSession);
    } catch (error, stackTrace) {
      state = V2boardAccountState(
        initialized: true,
        session: session,
        error: error,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await v2boardSessionStore.clear();
    state = const V2boardAccountState(initialized: true);
  }

  Future<void> _importSubscription(String url) async {
    await ref
        .read(profilesActionProvider.notifier)
        .importUrlProfile(url, label: v2boardProfileName);
  }
}
