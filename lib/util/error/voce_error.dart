import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/main.dart';

abstract class VoceError {}

class VoceAuthError extends VoceError {
  static const String emailAlreadyExists = 'authEmailAlreadyExists';
}

class VoceNetworkError {}

class VoceGeneralError {
  static const String unknownError = 'unknownError';
}

void showError(String errorKey) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  String errorMessage = AppLocalizations.of(context)!.generalErrorUnknownError;

  switch (errorKey) {
    case VoceAuthError.emailAlreadyExists:
      errorMessage = AppLocalizations.of(context)!.authErrorEmailAlreadyExists;
      break;
    case VoceGeneralError.unknownError:
      errorMessage = AppLocalizations.of(context)!.generalErrorUnknownError;
      break;
    default:
      errorMessage = AppLocalizations.of(context)!.generalErrorUnknownError;
  }

  ScaffoldMessenger.of(context).clearSnackBars();

  final snackBar = SnackBar(
    content: Text(errorMessage),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
