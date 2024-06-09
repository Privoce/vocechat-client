import 'dart:async';

import 'package:async/async.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vocechat_client/app.dart';

class FcmHelper {
  /// Get the Firebase Cloud Messaging token.
  ///
  /// This method will return the FCM token if it is available within 3 seconds.
  /// If not, it will return an empty string.
  static Future<String> getFcmToken() async {
    const int waitingSecs = 3;

    App.logger.info("starts fetching Firebase Token");
    String deviceToken = "";

    try {
      final cancellableOperation = CancelableOperation.fromFuture(
        FirebaseMessaging.instance.getToken(),
        onCancel: () {
          deviceToken = "";
          return;
        },
      ).then((token) {
        deviceToken = token ?? "";
      });

      Timer(Duration(seconds: waitingSecs), (() {
        if (deviceToken.isEmpty) {
          App.logger.info("FCM timeout (${waitingSecs}s), handled by VoceChat");
          cancellableOperation.cancel();
        }
      }));

      await Future.delayed(Duration(seconds: waitingSecs));
      App.logger.info("finishes fetching Firebase Token");
      return deviceToken;
    } catch (e) {
      App.logger.warning(e);
      deviceToken = "";
    }
    return deviceToken;
  }
}
