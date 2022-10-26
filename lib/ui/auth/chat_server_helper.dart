import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocechat_client/api/lib/admin_login_api.dart';
import 'package:vocechat_client/api/lib/admin_system_api.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/dao/org_dao/properties_models/chat_server_properties.dart';
import 'package:vocechat_client/ui/auth/server_page.dart';

class ChatServerHelper {
  BuildContext context;

  ChatServerHelper({required this.context});

  Future<ChatServerM?> prepareChatServerM(String url) async {
    ChatServerM chatServerM = ChatServerM();
    ServerStatusWithChatServerM s;

    if (!url.startsWith("https://") && !url.startsWith("http://")) {
      final httpsUrl = "https://" + url;

      s = await _checkServerAvailability(httpsUrl);
      if (s.status == ServerStatus.uninitialized) {
        await _showServerUninitializedError(s.chatServerM);
        return null;
      } else if (s.status == ServerStatus.available) {
        chatServerM = s.chatServerM;
      } else if (s.status == ServerStatus.error) {
        // test http
        final httpUrl = "http://" + url;
        s = await _checkServerAvailability(httpUrl);
        if (s.status == ServerStatus.uninitialized) {
          await _showServerUninitializedError(s.chatServerM);
          return null;
        } else if (s.status == ServerStatus.available) {
          chatServerM = s.chatServerM;
        } else if (s.status == ServerStatus.error) {
          await _showConnectionError();
          return null;
        }
      }
    } else {
      s = await _checkServerAvailability(url);
      if (s.status == ServerStatus.uninitialized) {
        await _showServerUninitializedError(s.chatServerM);
        return null;
      } else if (s.status == ServerStatus.available) {
        chatServerM = s.chatServerM;
      } else if (s.status == ServerStatus.error) {
        await _showConnectionError();
        return null;
      }
    }

    try {
      final adminSystemApi = AdminSystemApi(chatServerM.fullUrl);

      final orgInfoRes = await adminSystemApi.getOrgInfo();
      if (orgInfoRes.statusCode == 200 && orgInfoRes.data != null) {
        App.logger.info(orgInfoRes.data!.toJson().toString());
        final orgInfo = orgInfoRes.data!;
        chatServerM.properties = ChatServerProperties(
            serverName: orgInfo.name, description: orgInfo.description ?? "");

        final resourceApi = ResourceApi(chatServerM.fullUrl);
        final logoRes = await resourceApi.getOrgLogo();
        if (logoRes.statusCode == 200 && logoRes.data != null) {
          chatServerM.logo = logoRes.data!;
        }

        final AdminLoginApi adminLoginApi = AdminLoginApi(chatServerM.fullUrl);
        final adminLoginRes = await adminLoginApi.getConfig();
        if (adminLoginRes.statusCode == 200 && adminLoginRes.data != null) {
          chatServerM.properties = ChatServerProperties(
              serverName: orgInfo.name,
              description: orgInfo.description ?? "",
              config: adminLoginRes.data);
        }

        chatServerM.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await ChatServerDao.dao.addOrUpdate(chatServerM);
      } else {
        await _showConnectionError();
        return null;
      }
    } catch (e) {
      App.logger.severe(e);
      await _showConnectionError();
      return null;
    }

    App.app.chatServerM = chatServerM;
    return chatServerM;
  }

  Future<ServerStatusWithChatServerM> _checkServerAvailability(
      String url) async {
    ChatServerM chatServerM = ChatServerM();
    if (!chatServerM.setByUrl(url)) {
      return ServerStatusWithChatServerM(
          status: ServerStatus.error, chatServerM: chatServerM);
    }

    final adminSystemApi = AdminSystemApi(chatServerM.fullUrl);

    // Check if server has been initialized
    final initializedRes = await adminSystemApi.getInitialized();
    if (initializedRes.statusCode == 200 && initializedRes.data != true) {
      return ServerStatusWithChatServerM(
          status: ServerStatus.uninitialized, chatServerM: chatServerM);
    } else if (initializedRes.statusCode != 200) {
      return ServerStatusWithChatServerM(
          status: ServerStatus.error, chatServerM: chatServerM);
    }

    return ServerStatusWithChatServerM(
        status: ServerStatus.available, chatServerM: chatServerM);
  }

  Future<void> _showServerUninitializedError(ChatServerM chatServerM) async {
    return showAppAlert(
        context: context,
        title: "Server Not Initialized",
        content: "Please use web client for initialization.",
        actions: [
          AppAlertDialogAction(
              text: "Cancel", action: () => Navigator.of(context).pop()),
          AppAlertDialogAction(
              text: "Copy Url",
              action: () {
                Navigator.of(context).pop();

                final url = "${chatServerM.fullUrl}/#/onboarding";
                Clipboard.setData(ClipboardData(text: url));
              })
        ]);
  }

  Future<void> _showConnectionError() async {
    return showAppAlert(
        context: context,
        title: "Server Connection Error",
        content:
            "VoceChat can't retrieve server info. You may check url format, such as 'https' and 'http', or port number, or contact server owner for help.",
        actions: [
          AppAlertDialogAction(
            text: "OK",
            action: () {
              Navigator.of(context).pop();
            },
          )
        ]);
  }
}
