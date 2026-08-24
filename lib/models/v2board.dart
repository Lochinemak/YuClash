final class V2boardSession {
  final String baseUrl;
  final String email;
  final String authData;
  final String subscriptionUrl;

  const V2boardSession({
    required this.baseUrl,
    required this.email,
    required this.authData,
    required this.subscriptionUrl,
  });

  factory V2boardSession.fromJson(Map<String, Object?> json) {
    return V2boardSession(
      baseUrl: json['baseUrl'] as String,
      email: json['email'] as String,
      authData: json['authData'] as String,
      subscriptionUrl: json['subscriptionUrl'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'baseUrl': baseUrl,
      'email': email,
      'authData': authData,
      'subscriptionUrl': subscriptionUrl,
    };
  }

  V2boardSession copyWith({String? subscriptionUrl}) {
    return V2boardSession(
      baseUrl: baseUrl,
      email: email,
      authData: authData,
      subscriptionUrl: subscriptionUrl ?? this.subscriptionUrl,
    );
  }
}

final class V2boardAccountState {
  final bool initialized;
  final bool loading;
  final V2boardSession? session;
  final Object? error;

  const V2boardAccountState({
    this.initialized = false,
    this.loading = false,
    this.session,
    this.error,
  });
}
