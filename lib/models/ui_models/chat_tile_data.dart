import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/init_dao/user_settings.dart';
import 'package:vocechat_client/globals.dart' as globals;
import 'package:vocechat_client/main.dart';
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
  }

  ChatTileData.channel({required GroupInfoM groupInfoM}) : userInfoM = null {
    if (this.groupInfoM != null) {
      this.groupInfoM!.value = groupInfoM;
    } else {
      this.groupInfoM = ValueNotifier(groupInfoM);
    }
  }

  bool get isUser => userInfoM != null;
  bool get isChannel => groupInfoM != null;

  Future<void> setUser({UserInfoM? userInfoM}) async {
    if (userInfoM != null) {
      this.userInfoM?.value = userInfoM;
    }
    final userInfo = this.userInfoM!.value.userInfo;
    final properties = this.userInfoM!.value.properties;
    final dmSettings =
        await UserSettingsDao().getDmSettings(this.userInfoM!.value.uid);
    avatarUpdatedAt.value = userInfo.avatarUpdatedAt;

    title.value = userInfo.name;

    final latestMsgM =
        await ChatMsgDao().getDmLatestMsgM(userInfo.uid, withReactions: true);
    snippet.value =
        latestMsgM != null ? (await _processSnippet(latestMsgM)) : "";
    draft.value = properties.draft;

    updatedAt.value = latestMsgM?.createdAt ?? 0;
    unreadCount.value = await ChatMsgDao().getDmUnreadCount(userInfo.uid);

    isMuted.value = dmSettings?.enableMute ?? false;
    pinnedAt = dmSettings?.pinnedAt ?? 0;
    isPinned.value = pinnedAt > 0;
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
    final channelSettings =
        await UserSettingsDao().getGroupSettings(groupInfo.gid);

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

    isMuted.value = channelSettings?.enableMute ?? false;
    pinnedAt = channelSettings?.pinnedAt ?? 0;
    isPinned.value = pinnedAt > 0;
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

    if (chatMsgM.isNormalMsg || chatMsgM.isReplyMsg) {
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

  Future<void> mute() async {
    if (isChannel) {
      final gid = groupInfoM!.value.gid;
      final reqMap = {
        "add_groups": [
          {"gid": gid}
        ]
      };
      await UserApi().mute(json.encode(reqMap)).then((res) async {
        if (res.statusCode == 200) {
          await UserSettingsDao()
              .updateGroupSettings(gid, mute: true)
              .then((value) {
            if (value != null) {
              globals.userSettings.value = value;
            }
          });
        }
      });
    } else {
      final uid = userInfoM!.value.uid;
      final reqMap = {
        "add_users": [
          {"uid": uid}
        ]
      };
      await UserApi().mute(json.encode(reqMap)).then((res) async {
        if (res.statusCode == 200) {
          await UserSettingsDao()
              .updateDmSettings(uid, mute: true)
              .then((value) {
            if (value != null) {
              globals.userSettings.value = value;
            }
          });
        }
      });
    }
  }

  Future<void> unmute() async {
    if (isChannel) {
      final gid = groupInfoM!.value.gid;
      final reqMap = {
        "remove_groups": [gid]
      };
      await UserApi().mute(json.encode(reqMap)).then((res) async {
        if (res.statusCode == 200) {
          await UserSettingsDao()
              .updateGroupSettings(gid, mute: false)
              .then((value) {
            if (value != null) {
              globals.userSettings.value = value;
            }
          });
        }
      });
    } else {
      final uid = userInfoM!.value.uid;
      final reqMap = {
        "remove_users": [uid]
      };
      await UserApi().mute(json.encode(reqMap)).then((res) async {
        if (res.statusCode == 200) {
          await UserSettingsDao()
              .updateDmSettings(uid, mute: false)
              .then((value) {
            if (value != null) {
              globals.userSettings.value = value;
            }
          });
        }
      });
    }
  }

  Future<void> pin() async {
    if (isChannel) {
      await UserApi().pinChat(gid: groupInfoM!.value.gid).then((res) async {
        if (res.statusCode == 200) {
          await UserSettingsDao()
              .updateGroupSettings(groupInfoM!.value.gid,
                  pinnedAt: DateTime.now().millisecondsSinceEpoch)
              .then((value) {
            if (value != null) {
              globals.userSettings.value = value;
            }
          });
        }
      });
    } else if (isUser) {
      await UserApi().pinChat(uid: userInfoM!.value.uid).then((res) async {
        if (res.statusCode == 200) {
          await UserSettingsDao()
              .updateDmSettings(userInfoM!.value.uid,
                  pinnedAt: DateTime.now().millisecondsSinceEpoch)
              .then((value) {
            if (value != null) {
              globals.userSettings.value = value;
            }
          });
        }
      });
    }
  }

  Future<void> unpin() async {
    if (isChannel) {
      await UserApi().unpinChat(gid: groupInfoM!.value.gid).then((res) async {
        if (res.statusCode == 200) {
          await UserSettingsDao()
              .updateGroupSettings(groupInfoM!.value.gid, pinnedAt: null)
              .then((value) {
            if (value != null) {
              globals.userSettings.value = value;
            }
          });
        }
      });
    } else if (isUser) {
      await UserApi().unpinChat(uid: userInfoM!.value.uid).then((res) async {
        if (res.statusCode == 200) {
          await UserSettingsDao()
              .updateDmSettings(userInfoM!.value.uid, pinnedAt: null)
              .then((value) {
            if (value != null) {
              globals.userSettings.value = value;
            }
          });
        }
      });
    }
  }

  void clearSnippet() {
    snippet.value = "";
    unreadCount.value = 0;
    mentionsCount.value = 0;
  }

  void clearUnreadCount() {
    unreadCount.value = 0;
    mentionsCount.value = 0;
  }
}
