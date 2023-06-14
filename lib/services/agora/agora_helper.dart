import 'package:vocechat_client/api/lib/admin_agora_api.dart';
import 'package:vocechat_client/api/models/admin/agora/agora_token_response.dart';
import 'package:vocechat_client/app.dart';

class AgoraHelper {
  static Future<AgoraTokenResponse?> getAgoraToken() async {
    final uid = App.app.userDb?.uid;

    if (uid == null) {
      return null;
    }

    try {
      final res = await AdminAgoraApi().generateAgoraToken(uid);
      if (res.statusCode == 200) {
        return res.data;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }
}
