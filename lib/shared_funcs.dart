import 'package:vocechat_client/api/lib/admin_system_api.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/properties_models/chat_server_properties.dart';

class SharedFuncs {
  /// Get or update server information, including server name, description and
  /// logo image.
  static Future<bool> updateServerInfo() async {
    try {
      final orgInfoRes = await AdminSystemApi().getOrgInfo();
      if (orgInfoRes.statusCode == 200 && orgInfoRes.data != null) {
        final orgInfo = orgInfoRes.data!;
        App.app.chatServerM.properties = ChatServerProperties(
            serverName: orgInfo.name, description: orgInfo.description ?? "");

        final logoRes = await ResourceApi().getOrgLogo();
        if (logoRes.statusCode == 200 && logoRes.data != null) {
          App.app.chatServerM.logo = logoRes.data!;
        }

        App.app.chatServerM.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await ChatServerDao.dao.addOrUpdate(App.app.chatServerM);

        App.app.chatService.fireOrgInfo(App.app.chatServerM);

        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }
}
