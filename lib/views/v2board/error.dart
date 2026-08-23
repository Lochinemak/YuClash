import 'package:fl_clash/common/common.dart';
import 'package:flutter/widgets.dart';

String v2boardErrorText(BuildContext context, Object error) {
  if (error is! V2boardException) {
    return error.toString();
  }
  if (error.details != null) {
    return error.details!;
  }
  final appLocalizations = context.appLocalizations;
  return switch (error.type) {
    V2boardErrorType.invalidLoginResponse =>
      appLocalizations.invalidV2boardResponse,
    V2boardErrorType.missingSubscriptionUrl =>
      appLocalizations.missingV2boardSubscriptionUrl,
    V2boardErrorType.invalidServerUrl =>
      appLocalizations.invalidV2boardServerUrl,
    V2boardErrorType.invalidSubscriptionUrl =>
      appLocalizations.invalidV2boardSubscriptionUrl,
    V2boardErrorType.network => appLocalizations.networkException,
    V2boardErrorType.server => appLocalizations.unknownNetworkError,
  };
}
