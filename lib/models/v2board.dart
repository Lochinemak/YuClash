final class V2boardAccountOverview {
  final String email;
  final String avatarUrl;
  final String? planName;
  final int upload;
  final int download;
  final int total;
  final int? expire;
  final int onlineDevices;
  final int? deviceLimit;

  const V2boardAccountOverview({
    required this.email,
    required this.avatarUrl,
    required this.planName,
    required this.upload,
    required this.download,
    required this.total,
    required this.expire,
    required this.onlineDevices,
    required this.deviceLimit,
  });

  factory V2boardAccountOverview.fromJson(Map<String, Object?> json) {
    return V2boardAccountOverview(
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      planName: json['planName'] as String?,
      upload: (json['upload'] as num?)?.toInt() ?? 0,
      download: (json['download'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      expire: (json['expire'] as num?)?.toInt(),
      onlineDevices: (json['onlineDevices'] as num?)?.toInt() ?? 0,
      deviceLimit: (json['deviceLimit'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'email': email,
      'avatarUrl': avatarUrl,
      'planName': planName,
      'upload': upload,
      'download': download,
      'total': total,
      'expire': expire,
      'onlineDevices': onlineDevices,
      'deviceLimit': deviceLimit,
    };
  }
}

final class V2boardSubscriptionSnapshot {
  final String subscriptionUrl;
  final V2boardAccountOverview accountOverview;

  const V2boardSubscriptionSnapshot({
    required this.subscriptionUrl,
    required this.accountOverview,
  });
}

final class V2boardSession {
  final String baseUrl;
  final String email;
  final String authData;
  final String subscriptionUrl;
  final V2boardAccountOverview? accountOverview;

  const V2boardSession({
    required this.baseUrl,
    required this.email,
    required this.authData,
    required this.subscriptionUrl,
    this.accountOverview,
  });

  factory V2boardSession.fromJson(Map<String, Object?> json) {
    return V2boardSession(
      baseUrl: json['baseUrl'] as String,
      email: json['email'] as String,
      authData: json['authData'] as String,
      subscriptionUrl: json['subscriptionUrl'] as String,
      accountOverview: switch (json['accountOverview']) {
        final Map value => V2boardAccountOverview.fromJson(
          Map<String, Object?>.from(value),
        ),
        _ => null,
      },
    );
  }

  Map<String, Object?> toJson() {
    return {
      'baseUrl': baseUrl,
      'email': email,
      'authData': authData,
      'subscriptionUrl': subscriptionUrl,
      'accountOverview': accountOverview?.toJson(),
    };
  }

  V2boardSession copyWith({
    String? subscriptionUrl,
    V2boardAccountOverview? accountOverview,
  }) {
    return V2boardSession(
      baseUrl: baseUrl,
      email: email,
      authData: authData,
      subscriptionUrl: subscriptionUrl ?? this.subscriptionUrl,
      accountOverview: accountOverview ?? this.accountOverview,
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
