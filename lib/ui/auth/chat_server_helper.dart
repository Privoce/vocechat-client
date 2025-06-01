import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/api/lib/admin_system_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/services/url_redirect_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/auth/server_page.dart';

class ChatServerHelper {
  ChatServerHelper();

  /// url is the server domain, for example 'https://dev.voce.chat'.
  /// No http / https required.
  Future<ChatServerM?> prepareChatServerM(String url,
      {bool showAlert = true}) async {
    final context = navigatorKey.currentContext;

    ChatServerM chatServerM = ChatServerM();
    ServerStatusWithChatServerM s;
    
    // 保存原始URL，用于退出后再次登录
    String originalUrl = url;

    // 检查固定重定向的特殊URL
    if (url == "https://privoce.voce.chat") {
      url = "https://dev.voce.chat";
      originalUrl = url; // 更新原始URL为新的特定URL
    }

    // 处理URL重定向
    String redirectedUrl = url;
    
    // 确保URL格式正确，否则尝试添加协议
    if (!redirectedUrl.startsWith("https://") && !redirectedUrl.startsWith("http://")) {
      // 更新原始URL为带协议的URL
      String httpOriginalUrl = "https://$url";
      originalUrl = httpOriginalUrl;
      
      // 先尝试HTTPS
      redirectedUrl = await _processUrlWithRedirect(httpOriginalUrl);
      
      if (redirectedUrl == httpOriginalUrl) {
        // 如果URL没有被重定向，再尝试HTTP
        httpOriginalUrl = "http://$url";
        String httpRedirectedUrl = await _processUrlWithRedirect(httpOriginalUrl);
        if (httpRedirectedUrl != httpOriginalUrl) {
          // 如果HTTP版本有重定向，使用HTTP重定向的结果
          redirectedUrl = httpRedirectedUrl;
          originalUrl = httpOriginalUrl; // 更新原始URL为HTTP版本
        }
      }
    } else {
      // URL已经包含协议
      redirectedUrl = await _processUrlWithRedirect(url);
    }
    
    // 如果有重定向，记录日志
    if (redirectedUrl != url) {
      App.logger.info('服务器URL重定向: $url -> $redirectedUrl');
    }
    
    // 将原始URL和重定向URL都传递给_checkServerAvailability
    s = await _checkServerAvailability(redirectedUrl, originalUrl);
    if (s.status == ServerStatus.uninitialized) {
      if (showAlert && context != null) {
        await _showServerUninitializedError(s.chatServerM, context);
      }
      return null;
    } else if (s.status == ServerStatus.available) {
      chatServerM = s.chatServerM;
      
      // 确保保存原始URL - 这是关键修改点
      if (chatServerM.originalUrl.isEmpty) {
        chatServerM.originalUrl = originalUrl;
      }
    } else if (s.status == ServerStatus.error) {
      if (showAlert && context != null) {
        await _showConnectionError(context);
      }
      return null;
    }

    try {
      chatServerM =
          (await SharedFuncs.getServerInfo(chatServerM)) ?? chatServerM;
    } catch (e) {
      App.logger.severe(e);
      if (showAlert && context != null) {
        await _showConnectionError(context);
      }
      return null;
    }

    // 最后再次确认originalUrl被正确设置
    if (chatServerM.originalUrl.isEmpty) {
      chatServerM.originalUrl = originalUrl;
    }
    
    return chatServerM;
  }
  
  /// 处理URL重定向，返回最终的URL
  Future<String> _processUrlWithRedirect(String url) async {
    try {
      // 使用URL重定向服务获取最终的URL
      final redirectService = UrlRedirectService();
      return await redirectService.getRedirectedUrl(url);
    } catch (e) {
      App.logger.warning('处理URL重定向时出错: $e');
      return url;
    }
  }

  Future<ServerStatusWithChatServerM> _checkServerAvailability(
      String url, String originalUrl) async {
    ChatServerM chatServerM = ChatServerM();
    if (!chatServerM.setByUrl(url)) {
      return ServerStatusWithChatServerM(
          status: ServerStatus.error, chatServerM: chatServerM);
    }
    
    // 显式设置原始URL
    chatServerM.originalUrl = originalUrl;

    final adminSystemApi = AdminSystemApi(serverUrl: chatServerM.fullUrl);

    try {
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
    } catch (e) {
      App.logger.severe(e);
      return ServerStatusWithChatServerM(
          status: ServerStatus.error, chatServerM: chatServerM);
    }
  }

  Future<void> _showServerUninitializedError(
      ChatServerM chatServerM, BuildContext context) async {
    return showAppAlert(
        context: context,
        title:
            AppLocalizations.of(context)!.chatServerHelperServerNotInitialized,
        content: AppLocalizations.of(context)!
            .chatServerHelperServerNotInitializedContent,
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
              action: () => Navigator.of(context).pop()),
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.copyUrl,
              action: () {
                Navigator.of(context).pop();

                final url = "${chatServerM.fullUrl}/#/onboarding";
                Clipboard.setData(ClipboardData(text: url));
              })
        ]);
  }

  Future<void> _showConnectionError(BuildContext context) async {
    return showAppAlert(
        context: context,
        title:
            AppLocalizations.of(context)!.chatServerHelperServerConnectionError,
        content: AppLocalizations.of(context)!
            .chatServerHelperServerConnectionErrorContent,
        actions: [
          AppAlertDialogAction(
            text: AppLocalizations.of(context)!.ok,
            action: () {
              Navigator.of(context).pop();
            },
          )
        ]);
  }
}
