import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/shared_funcs.dart';

class ChatTileData {
  // The following variables are lists from left to right, then from top to
  // bottom in a [ChatTile]

  // First Col
  final ValueNotifier<int> avatarUpdatedAt = ValueNotifier(0);

  // Second Col
  final ValueNotifier<String> title = ValueNotifier("");
  final ValueNotifier<bool> isPrivateChannel =
      ValueNotifier(false); // Only for channels
  final ValueNotifier<String> snippet = ValueNotifier("");
  final ValueNotifier<String> draft = ValueNotifier("");

  // Third Col
  final ValueNotifier<int> updatedAt = ValueNotifier(0);
  final ValueNotifier<int> unreadCount = ValueNotifier(0);
  final ValueNotifier<int> mentionsCount =
      ValueNotifier(0); // Only for channels

  // Other properties
  final ValueNotifier<bool> isMuted = ValueNotifier(false);
  final ValueNotifier<bool> isPinned = ValueNotifier(false);

  // Non-UI properties
  ValueNotifier<UserInfoM>? userInfoM;
  ValueNotifier<GroupInfoM>? groupInfoM;
  int pinnedAt = -1;

  // UI properties
  /// Whether the [ChatPageController] is being prepared
  ///
  /// If true, the tile should disable its gesture, including tap.
  ValueNotifier<bool> isPreparing = ValueNotifier(false);

  ChatTileData.user({required UserInfoM userInfoM}) : groupInfoM = null {
    if (this.userInfoM != null) {
      this.userInfoM!.value = userInfoM;
    } else {
      this.userInfoM = ValueNotifier(userInfoM);
    }

    // App.app.chatService.subscribeUsers(onUser);
  }

  ChatTileData.channel({required GroupInfoM groupInfoM}) : userInfoM = null {
    if (this.groupInfoM != null) {
      this.groupInfoM!.value = groupInfoM;
    } else {
      this.groupInfoM = ValueNotifier(groupInfoM);
    }

    // App.app.chatService.subscribeGroups(onChannel);
  }

  bool get isUser => userInfoM != null;
  bool get isChannel => groupInfoM != null;

  Future<void> setUser({UserInfoM? userInfoM}) async {
    if (userInfoM != null) {
      this.userInfoM?.value = userInfoM;
    }
    final userInfo = this.userInfoM!.value.userInfo;
    final properties = this.userInfoM!.value.properties;

    avatarUpdatedAt.value = userInfo.avatarUpdatedAt;

    title.value = userInfo.name;

    final latestMsgM =
        await ChatMsgDao().getDmLatestMsgM(userInfo.uid, withReactions: true);
    snippet.value =
        latestMsgM != null ? (await _processSnippet(latestMsgM)) : "";
    draft.value = properties.draft;

    updatedAt.value = latestMsgM?.createdAt ?? 0;
    unreadCount.value = await ChatMsgDao().getDmUnreadCount(userInfo.uid);

    isMuted.value = properties.muteExpiresAt != null &&
        properties.muteExpiresAt! > 0 &&
        properties.muteExpiresAt! > DateTime.now().millisecondsSinceEpoch;

    pinnedAt = properties.pinnedAt ?? -1;
    isPinned.value = properties.pinnedAt != null && properties.pinnedAt! > 0;
  }

  static Future<ChatTileData?> fromUid(int uid) async {
    final userInfoM = await UserInfoDao().getUserByUid(uid);
    if (userInfoM != null) {
      return fromUser(userInfoM);
    }
    return null;
  }

  static Future<ChatTileData> fromUser(UserInfoM userInfoM) async {
    final voceChatTileData = ChatTileData.user(userInfoM: userInfoM);
    await voceChatTileData.setUser(userInfoM: userInfoM);
    return voceChatTileData;
  }

  /// Set channel data
  ///
  /// Must be called after a [ChatTileData] is created with
  /// [VoceChatTileData.channel]
  Future<void> setChannel({GroupInfoM? groupInfoM}) async {
    if (groupInfoM != null) {
      this.groupInfoM?.value = groupInfoM;
    }
    final groupInfo = this.groupInfoM!.value.groupInfo;
    final properties = this.groupInfoM!.value.properties;

    avatarUpdatedAt.value = groupInfo.avatarUpdatedAt;

    title.value = groupInfo.name;
    isPrivateChannel.value = !groupInfo.isPublic;

    final latestMsgM = await ChatMsgDao()
        .getChannelLatestMsgM(groupInfo.gid, withReactions: true);
    if (latestMsgM != null) {
      snippet.value = await _processSnippet(latestMsgM);
    }
    draft.value = properties.draft;

    updatedAt.value = latestMsgM?.createdAt ?? 0;
    unreadCount.value = await ChatMsgDao().getGroupUnreadCount(groupInfo.gid);
    mentionsCount.value =
        await ChatMsgDao().getGroupUnreadMentionCount(groupInfo.gid);

    isMuted.value = properties.muteExpiresAt != null &&
        properties.muteExpiresAt! > 0 &&
        properties.muteExpiresAt! > DateTime.now().millisecondsSinceEpoch;

    pinnedAt = properties.pinnedAt ?? -1;
    isPinned.value = properties.pinnedAt != null && properties.pinnedAt! > 0;
  }

  static Future<ChatTileData?> fromGid(int gid) async {
    final groupInfoM = await GroupInfoDao().getGroupByGid(gid);
    if (groupInfoM != null) {
      return fromChannel(groupInfoM);
    }
    return null;
  }

  static Future<ChatTileData> fromChannel(GroupInfoM groupInfoM) async {
    final voceChatTileData = ChatTileData.channel(groupInfoM: groupInfoM);
    await voceChatTileData.setChannel(groupInfoM: groupInfoM);
    return voceChatTileData;
  }

  static Future<ChatTileData?> fromChatMsgM(ChatMsgM chatMsgM) async {
    if (chatMsgM.isGroupMsg) {
      final groupInfoM = await GroupInfoDao().getGroupByGid(chatMsgM.gid);
      if (groupInfoM != null) {
        return fromChannel(groupInfoM);
      }
    } else {
      final userInfoM = await UserInfoDao().getUserByUid(chatMsgM.dmUid);
      if (userInfoM != null) {
        return fromUser(userInfoM);
      }
    }
    return null;
  }

  Future<String> _processSnippet(ChatMsgM chatMsgM) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return "";
    }
    String snippet;

    switch (chatMsgM.detailType) {
      case MsgDetailType.normal:
        switch (chatMsgM.detailContentType) {
          case MsgContentType.text:
            snippet = chatMsgM.reactionData?.hasEditedText == true
                ? chatMsgM.reactionData!.editedText!
                : chatMsgM.msgNormal?.content ??
                    chatMsgM.msgReply?.content ??
                    "";
            break;
          case MsgContentType.markdown:
            snippet =
                "[Markdown]${chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? ""}";

            break;
          case MsgContentType.file:
            final name = chatMsgM.msgNormal?.properties?["name"] ?? "";

            if (chatMsgM.isImageMsg) {
              snippet = "[${AppLocalizations.of(context)!.image}] $name";
            } else {
              snippet = "[${AppLocalizations.of(context)!.file}] $name";
            }
            break;
          case MsgContentType.archive:
            snippet = "[${AppLocalizations.of(context)!.archive}]";
            break;
          case MsgContentType.audio:
            snippet = "[${AppLocalizations.of(context)!.audioMessage}]";
            break;
          default:
            snippet =
                chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? "";
            break;
        }
        break;
      case MsgDetailType.reaction:
        switch (chatMsgM.msgReaction!.type) {
          case "edit":
            snippet = chatMsgM.msgReaction?.detail["content"] ?? "";
            break;
          default:
            snippet = AppLocalizations.of(context)!.unsupportedMessageType;
        }
        break;
      case MsgDetailType.reply:
        switch (chatMsgM.detailContentType) {
          case MsgContentType.text:
            snippet =
                chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? "";
            break;
          case MsgContentType.markdown:
            snippet =
                "[Markdown]${chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? ""}";

            break;
          default:
            snippet = AppLocalizations.of(context)!.unsupportedMessageType;
            break;
        }
        break;
      default:
        snippet = AppLocalizations.of(context)!.unsupportedMessageType;
    }
    if (chatMsgM.isGroupMsg) {
      final sender = await UserInfoDao().getUserByUid(chatMsgM.fromUid);

      final senderName = sender?.userInfo.name;
      if (senderName != null &&
          !SharedFuncs.isSelf(sender!.uid) &&
          senderName.isNotEmpty) {
        return "$senderName: ${await SharedFuncs.parseMention(snippet)}";
      }
    }
    return SharedFuncs.parseMention(snippet);
  }

  Future<void> updateByChatMsg(ChatMsgM chatMsgM) async {
    final dao = ChatMsgDao();
    if (chatMsgM.isGroupMsg) {
      if (chatMsgM.gid != groupInfoM?.value.gid) {
        return;
      }
    } else {
      if (chatMsgM.dmUid != userInfoM?.value.uid) {
        return;
      }
    }

    if (chatMsgM.isNormalMsg) {
      await setSnippet(chatMsgM);
    } else if (chatMsgM.isReactionMsg) {
      if (chatMsgM.isEditReactionMsg) {
        await setSnippet(chatMsgM);
      } else if (chatMsgM.isDeleteReactionMsg) {
        ChatMsgM? latestMsgM;
        if (chatMsgM.isGroupMsg) {
          latestMsgM = await dao.getChannelLatestMsgM(chatMsgM.gid);
        } else {
          latestMsgM = await dao.getDmLatestMsgM(chatMsgM.dmUid);
        }

        if (latestMsgM != null) {
          await setSnippet(latestMsgM);
        } else {
          setEmptySnippet();
        }
      }
    }
  }

  Future<void> setSnippet(ChatMsgM chatMsgM) async {
    final dao = ChatMsgDao();
    snippet.value = await _processSnippet(chatMsgM);

    updatedAt.value = chatMsgM.createdAt;

    if (chatMsgM.isGroupMsg) {
      unreadCount.value = await dao.getGroupUnreadCount(chatMsgM.gid);
      mentionsCount.value = await dao.getGroupUnreadMentionCount(chatMsgM.gid);
    } else {
      unreadCount.value = await dao.getDmUnreadCount(chatMsgM.dmUid);
    }
  }

  void setEmptySnippet() {
    snippet.value = "";
    unreadCount.value = 0;
    mentionsCount.value = 0;

    if (isChannel) {
      updatedAt.value = groupInfoM!.value.createdAt;
    } else {
      updatedAt.value = userInfoM!.value.createdAt;
    }
  }

  Future<void> setDraft(String draft) async {
    this.draft.value = draft;
  }

  // Future<void> onUser(UserInfoM userInfoM, EventActions action) async {
  //   if (userInfoM.uid != this.userInfoM?.value.uid) {
  //     return;
  //   }

  //   switch (action) {
  //     case EventActions.create:
  //     case EventActions.update:
  //       await setUser(userInfoM: userInfoM);
  //       break;
  //     case EventActions.delete:
  //       if (this.userInfoM!.value.uid == userInfoM.uid) {
  //         this.userInfoM = null;
  //       }
  //       break;
  //     default:
  //       break;
  //   }
  // }

  // Future<void> onChannel(GroupInfoM groupInfoM, EventActions action) async {
  //   if (groupInfoM.gid != this.groupInfoM?.value.gid) {
  //     return;
  //   }

  //   switch (action) {
  //     case EventActions.create:
  //     case EventActions.update:
  //       await setChannel(groupInfoM: groupInfoM);
  //       break;
  //     case EventActions.delete:
  //       if (this.groupInfoM!.value.gid == groupInfoM.gid) {
  //         this.groupInfoM = null;
  //       }
  //       break;
  //     default:
  //       break;
  //   }
  // }
}
