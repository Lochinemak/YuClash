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
    final session = await ref.read(v2boardSessionStoreProvider).load();
    state = V2boardAccountState(initialized: true, session: session);
    if (session != null) {
      unawaited(_refreshSession(session, importSubscription: false));
    }
  }

  Future<void> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    state = const V2boardAccountState(initialized: true, loading: true);
    try {
      final session = await ref
          .read(v2boardApiClientProvider)
          .login(baseUrl: baseUrl, email: email, password: password);
      await _importSubscription(session.subscriptionUrl);
      await ref.read(v2boardSessionStoreProvider).save(session);
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
    await _refreshSession(
      session,
      importSubscription: true,
      throwOnError: true,
    );
  }

  Future<void> _refreshSession(
    V2boardSession session, {
    required bool importSubscription,
    bool throwOnError = false,
  }) async {
    state = V2boardAccountState(
      initialized: true,
      loading: true,
      session: session,
    );
    try {
      final snapshot = await ref
          .read(v2boardApiClientProvider)
          .getSubscriptionSnapshot(
            baseUrl: session.baseUrl,
            authData: session.authData,
            fallbackEmail: session.email,
          );
      if (state.session?.authData != session.authData) {
        return;
      }
      if (importSubscription) {
        await _importSubscription(snapshot.subscriptionUrl);
      }
      if (state.session?.authData != session.authData) {
        return;
      }
      final nextSession = session.copyWith(
        subscriptionUrl: snapshot.subscriptionUrl,
        accountOverview: snapshot.accountOverview,
      );
      final store = ref.read(v2boardSessionStoreProvider);
      await store.save(nextSession);
      if (state.session?.authData != session.authData) {
        final currentSession = state.session;
        if (currentSession == null) {
          await store.clear();
        } else {
          await store.save(currentSession);
        }
        return;
      }
      state = V2boardAccountState(initialized: true, session: nextSession);
    } catch (error, stackTrace) {
      if (state.session?.authData != session.authData) {
        return;
      }
      state = V2boardAccountState(
        initialized: true,
        session: session,
        error: error,
      );
      if (throwOnError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  Future<void> logout() async {
    state = const V2boardAccountState(initialized: true);
    await ref.read(v2boardSessionStoreProvider).clear();
  }

  Future<void> _importSubscription(String url) async {
    await ref
        .read(profilesActionProvider.notifier)
        .importUrlProfile(url, label: v2boardProfileName);
  }
}
