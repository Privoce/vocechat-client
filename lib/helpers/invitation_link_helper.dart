import 'package:vocechat_client/app.dart';

class InvitationLinkHelper {
  static InvitationLinkData parseInvitationLink(String link) {
    try {
      final modifiedLink = link.trim().replaceFirst("/#", "");
      Uri uri = Uri.parse(modifiedLink).replace(fragment: '');

      // Special handling for privoce.voce.chat
      String host = uri.host;
      if (host == "privoce.voce.chat") {
        host = "dev.voce.chat";
      }

      final serverUrl =
          "${uri.scheme}://$host${uri.hasPort ? ":${uri.port}" : ""}";

      final magicToken = uri.queryParameters["magic_token"] as String;

      if (uri.pathSegments.length == 2 &&
          uri.pathSegments[0] == "invite_private") {
        return InvitationLinkData.invitePrivate(
          originalLink: link,
          serverUrl: serverUrl,
          magicToken: magicToken,
          privateChannelId: int.parse(uri.pathSegments[1]),
        );
      } else {
        return InvitationLinkData.register(
          originalLink: link,
          serverUrl: serverUrl,
          magicToken: magicToken,
        );
      }
    } catch (e) {
      App.logger.severe(e);
      rethrow;
    }
  }
}

class InvitationLinkData {
  String originalLink;

  String serverUrl;
  InvitationLinkType type;
  String magicToken;
  int? privateChannelId;

  InvitationLinkData._({
    required this.originalLink,
    required this.serverUrl,
    this.type = InvitationLinkType.invitePrivate,
    required this.magicToken,
    this.privateChannelId,
  });

  factory InvitationLinkData.invitePrivate({
    required String originalLink,
    required String serverUrl,
    required String magicToken,
    required int privateChannelId,
  }) {
    return InvitationLinkData._(
      originalLink: originalLink,
      serverUrl: serverUrl,
      type: InvitationLinkType.invitePrivate,
      magicToken: magicToken,
      privateChannelId: privateChannelId,
    );
  }

  factory InvitationLinkData.register({
    required String originalLink,
    String? privoceLink,
    required String serverUrl,
    required String magicToken,
  }) {
    return InvitationLinkData._(
      originalLink: originalLink,
      serverUrl: serverUrl,
      type: InvitationLinkType.register,
      magicToken: magicToken,
    );
  }
}

enum InvitationLinkType { invitePrivate, register }
