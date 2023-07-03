import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/api/models/admin/system/sys_common_info.dart';
import 'package:vocechat_client/api/models/group/group_info.dart';
import 'package:vocechat_client/api/models/msg/chat_msg.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/pinned_msg.dart';
import 'package:vocechat_client/api/models/resource/open_graphic_image.dart';
import 'package:vocechat_client/api/models/user/contact_info.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/api/models/user/user_info_update.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/archive.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/contacts.dart';
import 'package:vocechat_client/dao/init_dao/dm_info.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/open_graphic_thumbnail.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/user_settings.dart';
import 'package:vocechat_client/dao/init_dao/reaction.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/init_dao/user_settings.dart';
import 'package:vocechat_client/dao/org_dao/properties_models/chat_server_properties.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/file_handler/audio_file_handler.dart';
import 'package:vocechat_client/services/sse/sse.dart';
import 'package:vocechat_client/services/sse/sse_event_consts.dart';
import 'package:vocechat_client/services/sse/sse_queue.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/globals.dart' as globals;
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../dao/org_dao/chat_server.dart';

enum EventActions { create, delete, update }

typedef UsersAware = Future<void> Function(
    UserInfoM userInfoM, EventActions action, bool afterReady);
typedef GroupAware = Future<void> Function(
    GroupInfoM groupInfoM, EventActions action, bool afterReady);

typedef MsgAware = Future<void> Function(ChatMsgM chatMsgM, bool afterReady,
    {bool? snippetOnly});
typedef ReactionAware = Future<void> Function(
    ReactionM reaction, bool afterReady);

typedef MidDeleteAware = Future<void> Function(int targetMid);
typedef LocalmidDeleteAware = Future<void> Function(String localMid);
typedef UserStatusAware = Future<void> Function(int uid, bool isOnline);
typedef ChatServerAware = Future<void> Function(ChatServerM chatServerM);

class VoceChatService {
  VoceChatService() {
    setReadIndexTimer();

    sseQueue = SseQueue(
        closure: handleSseStream,
        afterTaskCheck: () async {
          // _handleReady();
        });
    mainTaskQueue = TaskQueue();
  }

  void dispose() {
    mainTaskQueue.cancel();
    sseQueue.clear();
    readIndexTimer.cancel();
    Sse.sse.close();
  }

  final Set<UsersAware> _userListeners = {};
  final Set<GroupAware> _groupListeners = {};
  final Set<MsgAware> _msgListeners = {};
  final Set<ReactionAware> _reactionListeners = {};
  final Set<MidDeleteAware> _midDeleteListeners = {};
  final Set<LocalmidDeleteAware> _lmidDeleteListeners = {};
  final Set<VoidCallback> _refreshListeners = {};
  final Set<UserStatusAware> _userStatusListeners = {};
  final Set<ChatServerAware> _chatServerListeners = {};

  late SseQueue sseQueue;
  late TaskQueue mainTaskQueue;
  late Timer readIndexTimer;

  bool afterReady = false;

  final Map<int, ChatMsgM> dmInfoMap = {}; // {uid: createdAt}

  final Map<int, ChatMsgM> msgMap = {};
  final Map<int, ReactionM> reactionMap = {};

  Future<void> preSseInits() async {
    final res = await UserApi().getUserContacts();

    if (res.statusCode == 200 && res.data != null) {
      final rawList = res.data!;
      final contactList = rawList.map((e) {
        return ContactM.fromContactInfo(e.targetUid, e.contactInfo.status,
            e.contactInfo.createdAt, e.contactInfo.updatedAt);
      }).toList();

      await ContactDao().batchAdd(contactList);
    }
    App.logger.info("Contact list initialized. total: ${res.data?.length}");
  }

  void initSse() async {
    Sse.sse.close();

    await Future.delayed(Duration(milliseconds: 500));

    App.app.statusService?.fireSseLoading(SseStatus.connecting);

    if (App.app.userDb == null) {
      App.logger.warning("App.app.userDb null. SSE not subscribed.");
      App.app.statusService?.fireSseLoading(SseStatus.disconnected);
      return;
    }

    Sse.sse.subscribeSseEvent(handleSseEvent);
    Sse.sse.subscribeReady((ready) {
      afterReady = ready;
    });

    try {
      preSseInits().then((_) => Sse.sse.connect());
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Map<int, int> readIndexGroup = {}; // {gid: mid}
  Map<int, int> readIndexUser = {}; // {uid: mid}
  void addUserReadIndex(int mid, int uid) {
    // Server will return 400 if uploaded uid is self.
    if (uid == App.app.userDb?.uid) {
      return;
    }

    if (readIndexUser[uid] == null) {
      readIndexUser[uid] = mid;
    } else {
      readIndexUser[uid] = max(readIndexUser[uid]!, mid);
    }
  }

  void addGroupReadIndex(int mid, int gid) async {
    if (readIndexGroup[gid] == null) {
      readIndexGroup[gid] = mid;
    } else {
      readIndexGroup[gid] = max(readIndexGroup[gid]!, mid);
    }
  }

  /// Update max mid that has been already read every 5 seconds.
  void setReadIndexTimer() async {
    readIndexTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      Map<String, List> readIndexMap = {};

      for (var key in readIndexUser.keys) {
        final entry = {"uid": key, "mid": readIndexUser[key]!};
        if (readIndexMap["users"] == null) {
          readIndexMap["users"] = [entry];
        } else {
          readIndexMap["users"]?.add(entry);
        }
      }

      for (var key in readIndexGroup.keys) {
        final entry = {"gid": key, "mid": readIndexGroup[key]!};
        if (readIndexMap["groups"] == null) {
          readIndexMap["groups"] = [entry];
        } else {
          readIndexMap["groups"]?.add(entry);
        }
      }

      if (readIndexMap.isNotEmpty) {
        App.logger.info(readIndexMap);

        UserApi().updateReadIndex(json.encode(readIndexMap));

        readIndexUser.clear();
        readIndexGroup.clear();
      }
    });
  }

  void subscribeUsers(UsersAware userAware) {
    unsubscribeUsers(userAware);
    _userListeners.add(userAware);
  }

  void unsubscribeUsers(UsersAware userAware) {
    _userListeners.remove(userAware);
  }

  void subscribeGroups(GroupAware groupAware) {
    unsubscribeGroups(groupAware);
    _groupListeners.add(groupAware);
  }

  void unsubscribeGroups(GroupAware groupAware) {
    _groupListeners.remove(groupAware);
  }

  void subscribeMsg(MsgAware msgAware) {
    unsubscribeMsg(msgAware);
    _msgListeners.add(msgAware);
  }

  void unsubscribeMsg(MsgAware msgAware) {
    _msgListeners.remove(msgAware);
  }

  void subscribeReaction(ReactionAware reactionAware) {
    unsubscribeReaction(reactionAware);
    _reactionListeners.add(reactionAware);
  }

  void unsubscribeReaction(ReactionAware reactionAware) {
    _reactionListeners.remove(reactionAware);
  }

  void subscribeMidDelete(MidDeleteAware deleteAware) {
    unsubscribeMidDelete(deleteAware);
    _midDeleteListeners.add(deleteAware);
  }

  void unsubscribeMidDelete(MidDeleteAware deleteAware) {
    _midDeleteListeners.remove(deleteAware);
  }

  void subscribeLmidDelete(LocalmidDeleteAware deleteAware) {
    unsubscribeLmidDelete(deleteAware);
    _lmidDeleteListeners.add(deleteAware);
  }

  void unsubscribeLmidDelete(LocalmidDeleteAware deleteAware) {
    _lmidDeleteListeners.remove(deleteAware);
  }

  void subscribeRefresh(VoidCallback refreshAware) {
    unsubscribeRefresh(refreshAware);
    _refreshListeners.add(refreshAware);
  }

  void unsubscribeRefresh(VoidCallback readyAware) {
    _refreshListeners.remove(readyAware);
  }

  void subscribeUserStatus(UserStatusAware statusAware) {
    unsubscribeUserStatus(statusAware);
    _userStatusListeners.add(statusAware);
  }

  void unsubscribeUserStatus(UserStatusAware statusAware) {
    _userStatusListeners.remove(statusAware);
  }

  void subscribeChatServer(ChatServerAware chatServerAware) {
    unsubscribeChatServer(chatServerAware);
    _chatServerListeners.add(chatServerAware);
  }

  void unsubscribeChatServer(ChatServerAware chatServerAware) {
    _chatServerListeners.remove(chatServerAware);
  }

  void fireUser(UserInfoM userInfoM, EventActions action, bool afterReady) {
    if (userInfoM.uid == App.app.userDb?.uid) {
      App.app.userDb!.info = userInfoM.info;
    }
    for (UsersAware userAware in _userListeners) {
      try {
        userAware(userInfoM, action, afterReady);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireChannel(
      GroupInfoM groupInfoM, EventActions action, bool afterReady) {
    for (GroupAware groupAware in _groupListeners) {
      try {
        groupAware(groupInfoM, action, afterReady);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  /// Fire the [targetMid] of a [ChatMsgM] that needs to be deleted to all
  /// listeners.
  ///
  /// Use this when firing *Delete* in *Reaction*. Only used for server-send
  /// deletion commands.
  void fireMidDelete(int targetMid) {
    for (MidDeleteAware deleteAware in _midDeleteListeners) {
      try {
        deleteAware(targetMid);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireLmidDelete(String localMid) {
    for (LocalmidDeleteAware deleteAware in _lmidDeleteListeners) {
      try {
        deleteAware(localMid);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  /// Fire a [ChatMsgM] object to all listeners.
  ///
  /// Use this when firing all types of messages except *Delete* in
  /// *Reaction*.
  void fireMsg(ChatMsgM chatMsgM, bool afterReady,
      {bool? snippetOnly = false}) {
    for (MsgAware msgAware in _msgListeners) {
      try {
        msgAware(chatMsgM, afterReady, snippetOnly: snippetOnly);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireReaction(ReactionM reaction, bool afterReady) {
    for (ReactionAware reactionAware in _reactionListeners) {
      try {
        reactionAware(reaction, afterReady);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireReady() {
    for (VoidCallback refreshAware in _refreshListeners) {
      try {
        refreshAware();
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireUserStatus(int uid, bool isOnline) {
    for (UserStatusAware statusAware in _userStatusListeners) {
      try {
        statusAware(uid, isOnline);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireChatServer(ChatServerM chatServerM) {
    for (ChatServerAware chatServerAware in _chatServerListeners) {
      try {
        chatServerAware(chatServerM);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  /// Only used to decide whether an SSE message needs to be put into queue.
  void handleSseEvent(dynamic event) {
    try {
      final map = json.decode(event) as Map<String, dynamic>;
      final type = map["type"];

      // Following methods listed in alphabetical order.
      switch (type) {
        case sseKick:
          App.app.statusService?.fireTokenLoading(TokenStatus.unauthorized);

          final context = navigatorKey.currentContext;
          if (context != null) {
            showAppAlert(
                context: context,
                title: AppLocalizations.of(context)!.loginSessionExpires,
                content:
                    AppLocalizations.of(context)!.loginSessionExpiresContent,
                actions: [
                  AppAlertDialogAction(
                      text: AppLocalizations.of(context)!.ok,
                      action: () => Navigator.pop(context))
                ]);
          }

          App.app.authService?.logout(markLogout: false, isKicked: true);
          // _handleKick();
          break;

        case sseHeartbeat:
          App.app.statusService?.fireSseLoading(SseStatus.successful);
          break;

        case sseChat:
        case sseGroupChanged:
        case sseJoinedGroup:
        case sseKickFromGroup:
        case sseMessageCleared:
        case ssePinnedMessageUpdated:
        case sseReady:
        case sseRelatedGroups:
        case sseServerConfigChanged:
        case sseUserJoinedGroup:
        case sseUserLeavedGroup:
        case sseUsersLog:
        case sseUserSettings:
        case sseUserSettingsChanged:
        case sseUsersSnapshot:
        case sseUsersState:
        case sseUsersStateChanged:
          sseQueue.add(event);
          break;

        default:
          break;
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  /// Handles SSE Stream data types
  Future<void> handleSseStream(dynamic event) async {
    try {
      final map = json.decode(event) as Map<String, dynamic>;
      final type = map["type"];

      // Following methods listed in alphabetical order.
      switch (type) {
        case sseChat:
          await _handleChatMsg(map);
          break;
        case sseGroupChanged:
          await _handleGroupChanged(map);
          break;
        case sseJoinedGroup:
          await _handleJoinedGroup(map);
          break;
        case sseKickFromGroup:
          await _handleKickFromGroup(map);
          break;
        case sseMessageCleared:
          await _handleMessageCleared(map);
          break;
        case ssePinnedMessageUpdated:
          await _handlePinnedMessageUpdated(map);
          break;
        case sseReady:
          await _handleReady();
          break;
        case sseRelatedGroups:
          await _handleRelatedGroups(map);
          break;
        case sseServerConfigChanged:
          await _handleServerConfigChanged(map);
          break;
        case sseUserJoinedGroup:
          await _handleUserJoinedGroup(map);
          break;
        case sseUserLeavedGroup:
          await _handleUserLeavedGroup(map);
          break;
        case sseUsersLog:
          await _handleUsersLog(map);
          break;
        case sseUserSettings:
          await _handleUserSettings(map);
          break;
        case sseUserSettingsChanged:
          await _handleUserSettingsChanged(map);
          break;
        case sseUsersSnapshot:
          await _handleUsersSnapshot(map);
          break;
        case sseUsersState:
          await _handleUsersState(map);
          break;
        case sseUsersStateChanged:
          await _handleUsersStateChanged(map);
          break;

        default:
          break;
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleChatMsg(Map<String, dynamic> chatJson) async {
    assert(chatJson.containsKey("type") && chatJson["type"] == sseChat);

    ChatMsg chatMsg = ChatMsg.fromJson(chatJson);

    // Cases that need to be ignored:
    // 1. unsent message in local (status == fail && uid == self);
    // 2. existing messages (sent by all, status == success && mid > -1)
    if (chatMsg.mid > -1) {
      final localMsg = await ChatMsgDao().getMsgByMid(chatMsg.mid);
      if (localMsg != null && localMsg.status == MsgStatus.success) {
        return;
      }
    }

    try {
      switch (chatMsg.detail["type"]) {
        case chatMsgNormal:
          await _handleMsgNormal(chatMsg);
          break;
        case chatMsgReaction:
          await _handleMsgReaction(chatMsg);
          break;
        case chatMsgReply:
          await _handleReply(chatMsg);
          break;
        default:
          final errorMsg =
              "MsgDetail format error. msg: ${chatJson.toString()}";
          App.logger.severe(errorMsg);
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<List<ChatMsgM>> handleServerHistory(dynamic data) async {
    Map<int, ChatMsgM> historyMsgMap = {};
    Map<int, ReactionM> historyReactionMap = {};

    final msgJsonList = data as List<dynamic>;

    try {
      for (final chatJson in msgJsonList) {
        ChatMsg chatMsg = ChatMsg.fromJson(chatJson);

        if (chatMsg.mid < 0) {
          continue;
        }

        String localMid;
        if (chatMsg.fromUid == App.app.userDb!.uid) {
          localMid = chatMsg.detail['properties']['cid'] ?? uuid();
        } else {
          localMid = uuid();
        }

        switch (chatMsg.detail["type"]) {
          case chatMsgNormal:
            ChatMsgM chatMsgM =
                ChatMsgM.fromMsg(chatMsg, localMid, MsgStatus.success);
            historyMsgMap.addAll({chatMsgM.mid: chatMsgM});

            break;
          case chatMsgReply:
            ChatMsgM chatMsgM =
                ChatMsgM.fromReply(chatMsg, localMid, MsgStatus.success);
            historyMsgMap.addAll({chatMsgM.mid: chatMsgM});

            break;
          case chatMsgReaction:
            final reactionM = ReactionM.fromChatMsg(chatMsg);
            if (reactionM != null) {
              historyReactionMap.addAll({reactionM.mid: reactionM});
            }
            break;
          default:
            break;
        }
      }

      final reactionDao = ReactionDao();
      await ChatMsgDao()
          .batchAdd(historyMsgMap.values.toList())
          .then((succeed) {
        if (!succeed) App.logger.severe("History message insert failed");
      });
      await reactionDao
          .batchAdd(historyReactionMap.values.toList())
          .then((succeed) {
        if (!succeed) App.logger.severe("History reaction insert failed");
      });

      // Prepare a final message list.
      final List<ChatMsgM> result = [];
      for (var msg in historyMsgMap.values.toList()) {
        msg.reactionData = await reactionDao.getReactions(msg.mid);
        result.add(msg);
      }

      return result;
    } catch (e) {
      App.logger.severe(e);
      return [];
    }
  }

  Future<void> _handleGroupChanged(Map<String, dynamic> map) async {
    assert(map["type"] == sseGroupChanged);

    try {
      final gid = map["gid"] as int;

      final oldGroupInfoM = await GroupInfoDao().getGroupByGid(gid);
      if (oldGroupInfoM != null) {
        final newGroupInfoM = await GroupInfoDao().updateGroup(map["gid"],
            description: map["description"],
            name: map["name"],
            owner: map["owner"],
            avatarUpdatedAt: map["avatar_updated_at"],
            isPublic: map["is_public"]);

        if (oldGroupInfoM != newGroupInfoM && newGroupInfoM != null) {
          fireChannel(newGroupInfoM, EventActions.update, afterReady);
        }
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleJoinedGroup(Map<String, dynamic> joinedGroupJson) async {
    assert(joinedGroupJson["type"] == sseJoinedGroup);

    try {
      final Map<String, dynamic> groupMap = joinedGroupJson["group"];

      final groupInfo = GroupInfo.fromJson(groupMap);
      GroupInfoM groupInfoM = GroupInfoM.fromGroupInfo(groupInfo, true);

      await GroupInfoDao().addOrUpdate(groupInfoM).then((value) async {
        fireChannel(value, EventActions.create, afterReady);
      });
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleKickFromGroup(Map<String, dynamic> map) async {
    assert(map['type'] == sseKickFromGroup);
    try {
      await GroupInfoDao().removeByGid(map["gid"]).then((value) {
        if (value != null) {
          fireChannel(value, EventActions.delete, afterReady);
        }
      });
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleMessageCleared(Map<String, dynamic> map) async {
    assert(map["type"] == sseMessageCleared);

    try {
      final latestDeletedMid = map["latest_deleted_mid"] as int;

      final context = navigatorKey.currentContext;
      if (context != null) {
        await showAppAlert(
            context: context,
            title: AppLocalizations.of(context)!.messageClearTitle,
            content: AppLocalizations.of(context)!.messageClearDes,
            actions: [
              AppAlertDialogAction(
                  text: AppLocalizations.of(context)!.ok,
                  action: () {
                    Navigator.of(context).pop();
                  })
            ]).then((_) async {
          await ChatMsgDao().clearChatMsgTable();
          await DmInfoDao().removeAll();
          await UserDbMDao.dao
              .updateMaxMid(App.app.userDb!.id, latestDeletedMid);
        });
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handlePinnedMessageUpdated(Map<String, dynamic> map) async {
    assert(map["type"] == ssePinnedMessageUpdated);

    // Keep old pin updates in groupInfo
    try {
      final int gid = map["gid"];
      final int mid = map["mid"];
      final msg = map["msg"];
      PinnedMsg? pinnedMsg;
      if (msg != null) {
        pinnedMsg = PinnedMsg.fromJson(msg);
      }
      await GroupInfoDao()
          .updatePins(gid, mid, pinnedMsg: pinnedMsg)
          .then((updatedGroupInfoM) async {
        final pinnedBy = pinnedMsg?.createdBy;
        await ChatMsgDao().pinMsgByMid(mid, pinnedBy ?? -1).then((updatedMsgM) {
          if (updatedGroupInfoM != null && updatedMsgM != null) {
            fireMsg(updatedMsgM, true);
            fireChannel(updatedGroupInfoM, EventActions.update, afterReady);
          }
        });
      });
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleReady() async {
    App.logger.info("SseService: Ready");
    deleteMemoryMsgs();

    // [saveMaxMid] must be called before [saveReactions] and [saveChatMsgs],
    // as the later functions will clear [msgMap] and [reactionMap].
    await saveMaxMid();
    await saveReactions();
    await saveChatMsgs();
    await saveDmInfoMap();

    afterReady = true;

    App.app.statusService?.fireSseLoading(SseStatus.successful);
    fireReady();
  }

  void deleteMemoryMsgs() {
    // Handle messages that have been deleted.
    for (final reaction in reactionMap.values) {
      final targetMid = reaction.targetMid;
      if (reaction.type == MsgReactionType.delete &&
          msgMap.containsKey(targetMid)) {
        msgMap.remove(targetMid);
      }
    }

    // Handle burn-after-read expired messages.
    // Data to be deleted should be stored in a temporary list,
    // as it is not allowed to modify the [msgMap] during the iteration.
    final List<int> expiredMids = [];
    for (final msgM in msgMap.values) {
      if (msgM.expired) {
        expiredMids.add(msgM.mid);
      }
    }
    for (final mid in expiredMids) {
      msgMap.remove(mid);
    }
  }

  Future<void> saveMaxMid() async {
    final maxMid = msgMap.values.fold<int>(0, (max, msg) {
      if (msg.mid > max) {
        return msg.mid;
      }
      return max;
    });

    final maxReactionMid = reactionMap.values.fold<int>(0, (max, reaction) {
      if (reaction.mid > max) {
        return reaction.mid;
      }
      return max;
    });

    final finalMaxMid = [maxMid, maxReactionMid].reduce(max);
    await UserDbMDao.dao.updateMaxMid(App.app.userDb!.id, finalMaxMid);
  }

  Future<void> saveChatMsgs() async {
    await ChatMsgDao().batchAdd(msgMap.values.toList()).then((succeed) {
      if (succeed) {
        App.logger.info("Chat messages saved. total: ${msgMap.length}");

        if (_msgListeners.isNotEmpty) {
          for (final msg in msgMap.values) {
            fireMsg(msg, true);
          }
        }
        msgMap.clear();
      }
    });
  }

  Future<void> saveReactions() async {
    await ReactionDao().batchAdd(reactionMap.values.toList()).then((succeed) {
      if (succeed) {
        App.logger.info("Reactions saved. total: ${reactionMap.length}");
        reactionMap.clear();
      }
    });
  }

  Future<void> saveDmInfoMap() async {
    final dmInfoDao = DmInfoDao();

    for (final each in dmInfoMap.values.toList()) {
      if (each.dmUid < 0) continue;
      final info = DmInfoM.item(each.dmUid, "", each.createdAt);
      await dmInfoDao.addOrUpdate(info);
    }

    App.logger.info("DmInfos saved. total: ${dmInfoMap.length}");
    dmInfoMap.clear();
  }

  Future<void> _handleRelatedGroups(Map<String, dynamic> relatedGroups) async {
    assert(relatedGroups.containsKey("type") &&
        relatedGroups["type"] == sseRelatedGroups);

    final channels = await GroupInfoDao().getAllGroupList();
    Set<int> localGids = {};
    if (channels != null) {
      localGids = Set.from(channels.map((e) => e.gid));
    }

    try {
      final List<dynamic> groupMaps = relatedGroups["groups"];
      final groups = groupMaps.map((e) => GroupInfo.fromJson(e));

      final serverGids = Set.from(groups.map((e) => e.gid));

      // Delete extra groups.
      for (final localGid in localGids) {
        if (!serverGids.contains(localGid)) {
          await FileHandler.singleton
              .deleteChatDirectory(SharedFuncs.getChatId(gid: localGid)!);
          await ChatMsgDao().deleteMsgByGid(localGid);
          await GroupInfoDao().deleteGroupByGid(localGid);

          final groupInfoM = GroupInfoM()..gid = localGid;

          fireChannel(groupInfoM, EventActions.delete, afterReady);
        }
      }

      // Update all existing groups.
      for (var groupInfo in groups) {
        if (!enablePublicChannels && groupInfo.isPublic) {
          continue;
        }

        GroupInfoM groupInfoM = GroupInfoM.fromGroupInfo(groupInfo, true);

        final oldGroupInfoM =
            await GroupInfoDao().getGroupByGid(groupInfoM.gid);

        if (oldGroupInfoM != groupInfoM) {
          await GroupInfoDao().addOrUpdate(groupInfoM).then((value) async {
            fireChannel(groupInfoM, EventActions.create, afterReady);
          });
        }
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleServerConfigChanged(Map<String, dynamic> map) async {
    assert(map['type'] == sseServerConfigChanged);

    String? organizationName;
    String? organizationDescription;
    String? organizationLogo;
    bool? showUserOnlineStatus;
    bool? contactVerificationEnable;
    String? chatLayoutMode;
    String? maxFileExpiryMode;

    try {
      organizationName = map["organization_name"] as String?;
      organizationDescription = map["organization_description"] as String?;
      organizationLogo = map["organization_logo"] as String?;
      showUserOnlineStatus = map["show_user_online_status"] as bool?;
      contactVerificationEnable = map["contact_verification_enable"] as bool?;
      chatLayoutMode = map["chat_layout_mode"] as String?;
      maxFileExpiryMode = map["max_file_expiry_mode"] as String?;

      final serverId = App.app.userDb?.chatServerId;
      if (serverId == null) return;

      ChatServerM? chatServerM =
          await ChatServerDao.dao.getServerById(serverId);
      if (chatServerM == null) return;

      // Update organization info.
      try {
        if (organizationLogo != null) {
          final logoRes = await ResourceApi().getOrgLogo();
          if (logoRes.statusCode == 200 && logoRes.data != null) {
            chatServerM.logo = logoRes.data!;
          }
        }
      } catch (e) {
        App.logger.severe(e);
      }

      ChatServerProperties properties = chatServerM.properties;

      properties.serverName = organizationName ?? properties.serverName;
      properties.description =
          organizationDescription ?? properties.description;

      final newCommonInfo = AdminSystemCommonInfo(
        showUserOnlineStatus:
            showUserOnlineStatus ?? properties.commonInfo?.showUserOnlineStatus,
        contactVerificationEnable: contactVerificationEnable ??
            properties.commonInfo?.contactVerificationEnable,
        chatLayoutMode: chatLayoutMode ?? properties.commonInfo?.chatLayoutMode,
        maxFileExpiryMode:
            maxFileExpiryMode ?? properties.commonInfo?.maxFileExpiryMode,
      );

      properties.commonInfo = newCommonInfo;
      chatServerM.properties = properties;

      await ChatServerDao.dao.addOrUpdate(chatServerM).then((value) {
        App.app.chatServerM = chatServerM;
        fireChatServer(value);
      });
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleUserJoinedGroup(Map<String, dynamic> map) async {
    assert(map['type'] == sseUserJoinedGroup);

    try {
      final gid = map["gid"] as int;
      final uids = List<int>.from(map["uid"]);

      await GroupInfoDao().addMembers(gid, uids).then((value) {
        if (value != null) {
          fireChannel(value, EventActions.update, afterReady);
        }
      });
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleUserLeavedGroup(Map<String, dynamic> map) async {
    assert(map['type'] == sseUserLeavedGroup);

    try {
      final gid = map["gid"] as int;
      final uids = List<int>.from(map["uid"]);

      if (uids.contains(App.app.userDb!.uid)) {
        // Myself quit the channel.
        await FileHandler.singleton
            .deleteChatDirectory(SharedFuncs.getChatId(gid: gid)!);
        await ChatMsgDao().deleteMsgByGid(gid);
        await GroupInfoDao().removeByGid(gid).then((value) {
          if (value != null) {
            fireChannel(value, EventActions.delete, afterReady);
          }
        });
      } else {
        await GroupInfoDao().removeMembers(gid, uids).then((value) {
          if (value != null) {
            fireChannel(value, EventActions.update, afterReady);
          }
        });
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleUsersLog(Map<String, dynamic> usersLog) async {
    assert(usersLog.containsKey("type") && usersLog["type"] == sseUsersLog);

    try {
      final List<dynamic> usersMap = usersLog["logs"];
      if (usersMap.isNotEmpty) {
        for (var userMap in usersMap) {
          String action = userMap["action"];

          switch (action) {
            case "create":
              UserInfo userInfo = UserInfo.fromJson(userMap);
              UserInfoM userInfoM = UserInfoM.fromUserInfo(userInfo, "");

              final oldUserInfoM =
                  await UserInfoDao().getUserByUid(userInfoM.uid);

              if (oldUserInfoM != userInfoM) {
                await UserInfoDao().addOrUpdate(userInfoM).then((value) async {
                  fireUser(value, EventActions.create, afterReady);
                });
              }

              await UserDbMDao.dao.updateUserInfo(userInfo);

              break;
            case "update":
              UserInfoUpdate update = UserInfoUpdate.fromJson(userMap);
              final old = await UserInfoDao().getUserByUid(update.uid);
              if (old != null) {
                final oldInfo = UserInfo.fromJson(json.decode(old.info));
                final newInfo = UserInfo.getUpdated(oldInfo, update);
                final newUserInfoM =
                    UserInfoM.fromUserInfo(newInfo, old.propertiesStr);

                if (old != newUserInfoM) {
                  await UserInfoDao()
                      .addOrUpdate(newUserInfoM)
                      .then((value) async {
                    fireUser(value, EventActions.update, afterReady);
                  });
                }
              }
              break;
            case "delete":
              final uid = userMap["uid"] as int?;
              if (uid != null) {
                UserInfoM userDeleted = UserInfoM()..uid = uid;

                await UserInfoDao().removeByUid(uid).then((value) =>
                    fireUser(userDeleted, EventActions.delete, afterReady));

                if (uid == App.app.userDb?.uid) {
                  await App.app.authService?.selfDelete();
                }
              }

              break;
            default:
          }
          int version = userMap["log_id"];

          await UserDbMDao.dao.updateUsersVersion(App.app.userDb!.id, version);
        }
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleUserSettings(Map<String, dynamic> map) async {
    assert(map["type"] == sseUserSettings);

    UserSettings userSettings = UserSettings();

    {
      // Burn after reading groups
      final burnAfterReadingGroups = map["burn_after_reading_groups"] as List?;
      if (burnAfterReadingGroups != null) {
        final Map<int, int> gidMap = {};
        for (final each in burnAfterReadingGroups) {
          final gid = each["gid"] as int?;
          final expiresIn = each["expires_in"] as int?;
          if (gid != null && expiresIn != null) {
            gidMap.addAll({gid: expiresIn});
          }
        }
        userSettings.burnAfterReadingGroups = gidMap;
      }
    }

    {
      // Burn after reading users
      final burnAfterReadingUsers = map["burn_after_reading_users"] as List?;
      if (burnAfterReadingUsers != null) {
        final Map<int, int> uidMap = {};
        for (final each in burnAfterReadingUsers) {
          final uid = each["uid"] as int?;
          final expiresIn = each["expires_in"] as int?;
          if (uid != null && expiresIn != null) {
            uidMap.addAll({uid: expiresIn});
          }
        }
        userSettings.burnAfterReadingUsers = uidMap;
      }
    }

    {
      // Mute Groups
      final muteGroups = map["mute_groups"] as List?;
      if (muteGroups != null) {
        final Map<int, int?> gidMap = {};
        for (final each in muteGroups) {
          final gid = each["gid"] as int?;
          final expiredAt = each["expired_at"] as int?;
          if (gid != null) {
            gidMap.addAll({gid: expiredAt});
          }
        }
        userSettings.muteGroups = gidMap;
      }
    }

    {
      // Mute Users
      final muteUsers = map["mute_users"] as List?;
      if (muteUsers != null) {
        final Map<int, int?> uidMap = {};
        for (final each in muteUsers) {
          final uid = each["uid"] as int?;
          final expiredAt = each["expired_at"] as int?;
          if (uid != null) {
            uidMap.addAll({uid: expiredAt});
          }
        }
        userSettings.muteUsers = uidMap;
      }
    }

    {
      // Pinned chats: pinned groups + pinned users
      final pinnedChats = map["pinned_chats"] as List?;
      if (pinnedChats != null) {
        final Map<int, int> pinnedGroups = {};
        final Map<int, int> pinnedUsers = {};

        for (final each in pinnedChats) {
          final gid = each["target"]["gid"] as int?;
          final uid = each["target"]["uid"] as int?;
          final pinnedAt = each["updated_at"] as int?;

          if (gid != null && pinnedAt != null) {
            pinnedGroups.addAll({gid: pinnedAt});
          } else if (uid != null && pinnedAt != null) {
            pinnedUsers.addAll({uid: pinnedAt});
          }
        }
        userSettings.pinnedGroups = pinnedGroups;
        userSettings.pinnedUsers = pinnedUsers;
      }
    }

    {
      // read index groups
      final readIndexGroups = map["read_index_groups"] as List?;
      if (readIndexGroups != null) {
        final Map<int, int> gidMap = {};
        for (final each in readIndexGroups) {
          final mid = each["mid"] as int?;
          final gid = each["gid"] as int?;
          if (mid != null && gid != null) {
            gidMap.addAll({gid: mid});
          }
        }
        userSettings.readIndexGroups = gidMap;
      }
    }

    {
      // read index users
      final readIndexUsers = map["read_index_users"] as List?;
      if (readIndexUsers != null) {
        final Map<int, int> uidMap = {};
        for (final each in readIndexUsers) {
          final mid = each["mid"] as int?;
          final uid = each["uid"] as int?;
          if (mid != null && uid != null) {
            uidMap.addAll({uid: mid});
          }
        }
        userSettings.readIndexUsers = uidMap;
      }
    }

    // This will only be called before 'afterReady' is pushed.
    // Thus no 'fire' event is needed.
    await UserSettingsDao()
        .addOrUpdate(UserSettingsM.fromUserSettings(userSettings))
        .then((value) {
      globals.userSettings.value = value.settings;
    });
  }

  Future<void> _handleUserSettingsChanged(Map<String, dynamic> map) async {
    assert(map['type'] == sseUserSettingsChanged);

    final currentUserSettings = await UserSettingsDao().getSettings();
    if (currentUserSettings == null) return;

    {
      // Burn after reading groups
      final burnAfterReadingGroups = map["burn_after_reading_groups"] as List?;
      if (burnAfterReadingGroups != null) {
        for (final each in burnAfterReadingGroups) {
          final gid = each["gid"] as int?;
          final expiresIn = (each["expires_in"] as int?) ?? 0;

          if (gid != null) {
            await UserSettingsDao()
                .updateGroupSettings(gid, burnAfterReadSecond: expiresIn)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // Burn after reading users
      final burnAfterReadingUsers = map["burn_after_reading_users"] as List?;
      if (burnAfterReadingUsers != null) {
        for (final each in burnAfterReadingUsers) {
          final uid = each["uid"] as int?;
          final expiresIn = (each["expires_in"] as int?) ?? 0;

          if (uid != null) {
            await UserSettingsDao()
                .updateDmSettings(uid, burnAfterReadSecond: expiresIn)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // Add mute groups
      final addMuteGroups = map["add_mute_groups"] as List?;
      if (addMuteGroups != null) {
        for (final each in addMuteGroups) {
          final gid = each["gid"] as int?;
          final expiredAt = each["expired_at"] as int?;

          if (gid != null) {
            await UserSettingsDao()
                .updateGroupSettings(gid, muteExpiredAt: expiredAt)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // Remove mute groups
      final removeMuteGroups = map["remove_mute_groups"] as List?;
      if (removeMuteGroups != null) {
        for (final each in removeMuteGroups) {
          final gid = each as int?;

          if (gid != null) {
            await UserSettingsDao()
                .updateGroupSettings(gid, muteExpiredAt: 0)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // Add mute users
      final addMuteUsers = map["add_mute_users"] as List?;
      if (addMuteUsers != null) {
        for (final each in addMuteUsers) {
          final uid = each["uid"] as int?;
          final expiredAt = each["expired_at"] as int?;

          if (uid != null) {
            await UserSettingsDao()
                .updateDmSettings(uid, muteExpiredAt: expiredAt)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // Remove mute users
      final removeMuteUsers = map["remove_mute_users"] as List?;
      if (removeMuteUsers != null) {
        for (final each in removeMuteUsers) {
          final uid = each as int?;

          if (uid != null) {
            await UserSettingsDao()
                .updateDmSettings(uid, muteExpiredAt: 0)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // update read index groups
      final readIndexGroups = map["read_index_groups"] as List?;
      if (readIndexGroups != null) {
        for (final each in readIndexGroups) {
          final mid = each["mid"] as int?;
          final gid = each["gid"] as int?;

          if (mid != null && gid != null) {
            await UserSettingsDao()
                .updateGroupSettings(gid, readIndex: mid)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // update read index users
      final readIndexUsers = map["read_index_users"] as List?;
      if (readIndexUsers != null) {
        for (final each in readIndexUsers) {
          final mid = each["mid"] as int?;
          final uid = each["uid"] as int?;

          if (mid != null && uid != null) {
            await UserSettingsDao()
                .updateDmSettings(uid, readIndex: mid)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // add pin chats
      final addPinChats = map["add_pin_chats"] as List?;
      if (addPinChats != null) {
        for (final each in addPinChats) {
          final gid = each["target"]["gid"] as int?;
          final uid = each["target"]["uid"] as int?;
          final updatedAt = each["updated_at"] as int?;

          if (gid != null && updatedAt != null) {
            await UserSettingsDao()
                .updateGroupSettings(gid, pinnedAt: updatedAt)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }

          if (uid != null && updatedAt != null) {
            await UserSettingsDao()
                .updateDmSettings(uid, pinnedAt: updatedAt)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // remove pin chats
      final removePinChats = map["remove_pin_chats"] as List?;
      if (removePinChats != null) {
        for (final each in removePinChats) {
          final gid = each["gid"] as int?;
          final uid = each["uid"] as int?;

          if (gid != null) {
            await UserSettingsDao()
                .updateGroupSettings(gid, pinnedAt: 0)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }

          if (uid != null) {
            await UserSettingsDao()
                .updateDmSettings(uid, pinnedAt: 0)
                .then((value) {
              if (value != null) {
                globals.userSettings.value = value;
              }
            });
          }
        }
      }
    }

    {
      // add contact
      final addContacts = map["add_contacts"] as List?;
      if (addContacts != null) {
        for (final each in addContacts) {
          final uid = each["target_uid"] as int?;
          final statusStr = each["info"]["status"] as String?;
          final createdAt = each["info"]["created_at"] as int?;
          final updatedAt = each["info"]["updated_at"] as int?;

          if (uid != null &&
              statusStr != null &&
              createdAt != null &&
              updatedAt != null) {
            final contactM =
                ContactM.fromContactInfo(uid, statusStr, createdAt, updatedAt);
            await ContactDao().addOrUpdate(contactM).then((value) {
              UserInfoDao().getUserByUid(uid).then((value) {
                if (value != null) {
                  fireUser(value, EventActions.update, afterReady);
                }
              });
            });
          }
        }
      }
    }

    {
      // remove contact
      final removeContacts = map["remove_contacts"] as List?;
      if (removeContacts != null) {
        for (final each in removeContacts) {
          final uid = each;

          if (uid != null) {
            await ContactDao().removeContact(uid).then((value) {
              UserInfoDao().getUserByUid(uid).then((value) {
                if (value != null) {
                  fireUser(value, EventActions.update, afterReady);
                }
              });
            });
          }
        }
      }
    }
  }

  Future<void> _handleUsersSnapshot(Map<String, dynamic> usersSnapshot) async {
    assert(usersSnapshot.containsKey("type") &&
        usersSnapshot["type"] == sseUsersSnapshot);

    final dao = UserInfoDao();

    try {
      final List<dynamic> userMaps = usersSnapshot["users"];
      final userInfoMList = userMaps.map((e) {
        final userInfo = UserInfo.fromJson(e);
        return UserInfoM.fromUserInfo(userInfo, "");
      }).toList();

      await dao.batchAdd(userInfoMList);

      final int version = usersSnapshot["version"];

      await UserDbMDao.dao
          .updateUsersVersion(App.app.userDb!.id, version)
          .then((userDbM) => App.app.userDb = userDbM);

      fireReady();
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleUsersState(Map<String, dynamic> map) async {
    assert(map["type"] == "users_state");

    try {
      final List<dynamic> stateMaps = map["users"];
      if (stateMaps.isNotEmpty) {
        for (var stateMap in stateMaps) {
          final uid = stateMap["uid"] as int;
          final isOnline = stateMap["online"] as bool;

          if (App.app.onlineStatusMap.containsKey(uid)) {
            App.app.onlineStatusMap[uid]!.value = isOnline;
          } else {
            App.app.onlineStatusMap[uid] = ValueNotifier(isOnline);
          }

          fireUserStatus(uid, isOnline);
        }
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleUsersStateChanged(Map<String, dynamic> map) async {
    assert(map["type"] == sseUsersStateChanged);

    try {
      final uid = map["uid"] as int;
      final isOnline = map["online"] as bool;

      if (App.app.onlineStatusMap.containsKey(uid)) {
        App.app.onlineStatusMap[uid]!.value = isOnline;
      } else {
        App.app.onlineStatusMap[uid] = ValueNotifier(isOnline);
      }

      fireUserStatus(uid, isOnline);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleMsgNormal(ChatMsg chatMsg) async {
    String localMid;
    if (chatMsg.fromUid == App.app.userDb!.uid) {
      localMid = chatMsg.detail['properties']?['cid'] ?? uuid();
    } else {
      localMid = uuid();
    }

    try {
      ChatMsgM chatMsgM =
          ChatMsgM.fromMsg(chatMsg, localMid, MsgStatus.success);
      await cumulateMsg(chatMsgM);
      await cumulateDmInfo(chatMsgM);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> cumulateMsg(ChatMsgM chatMsgM) async {
    if (afterReady) {
      await ChatMsgDao().addOrUpdate(chatMsgM).then((dbMsgM) async {
        await ReactionDao().getReactions(dbMsgM.mid).then((reactions) {
          dbMsgM.reactionData = reactions;
          fireMsg(dbMsgM, afterReady);
        });

        await UserDbMDao.dao.updateMaxMid(App.app.userDb!.id, dbMsgM.mid);
      });
    } else {
      msgMap.addAll({chatMsgM.mid: chatMsgM});
    }
  }

  Future<void> cumulateDmInfo(ChatMsgM chatMsgM) async {
    if (afterReady) {
      final info = DmInfoM.item(chatMsgM.dmUid, "", chatMsgM.createdAt);
      await DmInfoDao().addOrUpdate(info);
    } else {
      dmInfoMap.addAll({chatMsgM.dmUid: chatMsgM});
    }
  }

  Future<void> _handleMsgReaction(ChatMsg chatMsg) async {
    final msgReactionJson = chatMsg.detail;

    assert(msgReactionJson["type"] == "reaction");

    try {
      if (msgReactionJson["detail"]["type"] == 'delete') {
        final int? targetMid = chatMsg.detail["mid"];

        if (targetMid == null) return;

        if (afterReady) {
          ChatMsgDao().deleteMsgByMid(targetMid).then((mid) async {
            if (mid < 0) return;

            int? gid = chatMsg.target["gid"];
            int? uid = chatMsg.target["uid"];

            // Must be kept to get real dmUid.
            if (uid != null && SharedFuncs.isSelf(uid)) {
              uid = chatMsg.fromUid;
            }

            // Delete message in UI and its related files in file system.
            {
              fireMidDelete(targetMid);
              FileHandler.singleton
                  .deleteWithChatMsgM(ChatMsgM()..mid = targetMid);
              AudioFileHandler().deleteWithChatMsgM(ChatMsgM()
                ..mid = targetMid
                ..gid = gid ?? -1
                ..dmUid = uid ?? -1);
            }

            // Update latest message in UI.
            {
              final dao = ChatMsgDao();
              ChatMsgM? latestMsgM;

              if (gid != null) {
                latestMsgM = await dao.getChannelLatestMsgM(gid);
              } else if (uid != null) {
                latestMsgM = await dao.getDmLatestMsgM(uid);
              }
              if (latestMsgM != null) {
                await ReactionDao()
                    .getReactions(latestMsgM.mid)
                    .then((reactions) {
                  latestMsgM!.reactionData = reactions;
                  fireMsg(latestMsgM, afterReady, snippetOnly: true);
                });
              }
            }
          });
        } else {
          msgMap.remove(targetMid);
        }
      } else {
        final reactionM = ReactionM.fromChatMsg(chatMsg);
        if (reactionM != null) {
          if (afterReady) {
            await ReactionDao()
                .addOrReplace(reactionM)
                .then((savedReactionM) async {
              final targetMid = savedReactionM.targetMid;
              final originalMsgM = await ChatMsgDao().getMsgByMid(targetMid);
              final reactionData = await ReactionDao().getReactions(targetMid);

              if (originalMsgM != null) {
                originalMsgM.reactionData = reactionData;
                fireMsg(originalMsgM, afterReady);
              }
            });
          } else {
            reactionMap.addAll({reactionM.mid: reactionM});
          }
        }
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleReply(ChatMsg chatMsg) async {
    final msgReplyJson = chatMsg.detail;

    assert(msgReplyJson["type"] == "reply");

    final isSelf = chatMsg.fromUid == App.app.userDb!.uid;

    String localMid;
    if (isSelf) {
      localMid = chatMsg.detail['properties']?['cid'] ?? uuid();
    } else {
      localMid = uuid();
    }

    try {
      ChatMsgM chatMsgM =
          ChatMsgM.fromReply(chatMsg, localMid, MsgStatus.success);
      await cumulateMsg(chatMsgM);
      await cumulateDmInfo(chatMsgM);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<OpenGraphicThumbnailM?> createOpenGraphicThumbnail(
      String msg, String localMid, ChatMsgM? chatMsgM) async {
    RegExp urlRegExp = RegExp(urlRegEx);
    final urlMatch = urlRegExp.allMatches(msg);
    final List<String> urlList = [];
    for (var item in urlMatch) {
      urlList.add(item[0]!);
    }
    if (urlList.isNotEmpty) {
      for (var element in urlList) {
        if (element.substring(0, 4) != 'http') {
          element = 'http://' + element;
        }
        // try {
        final resourceApi = ResourceApi();
        final res = await resourceApi.getOpenGraphicParse(element);

        if (res.statusCode == 200 && res.data != null) {
          if (res.data!.images.isNotEmpty) {
            List<OpenGraphicImage> openGraphicImage = res.data!.images;
            for (var list in openGraphicImage) {
              if (list.url!.isNotEmpty) {
                Uint8List bytes =
                    (await NetworkAssetBundle(Uri.parse(list.url!))
                            .load(list.url!))
                        .buffer
                        .asUint8List();
                final openGraphicThumbnailM = OpenGraphicThumbnailM.item(
                  localMid,
                  element,
                  bytes,
                  res.data!.siteName,
                  res.data!.title,
                  res.data!.description,
                  res.data!.url,
                  DateTime.now().millisecondsSinceEpoch,
                );

                await OpenGraphicThumbnailDao()
                    .addOrUpdate(openGraphicThumbnailM);
                return openGraphicThumbnailM;
              }
            }
          }
        }
        // } catch (e) {
        //   App.logger.severe(e);
        // }
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getOpenGraphicThumbnail(
      ChatMsgM chatMsgM) async {
    final List<Map<String, dynamic>> _list = [];
    final Map<String, dynamic> _map = {};
    return await OpenGraphicThumbnailDao()
        .getThumb(chatMsgM.localMid)
        .catchError((e) {
      App.logger.severe(e);
      return null;
    }).then((value) {
      if (value != null) {
        for (var item in value) {
          _map['thumbnail'] = item.thumbnail;
          _map['siteName'] = item.siteName;
          _map['title'] = item.title;
          _map['desc'] = item.description;
          _map['url'] = item.url;
          _list.add(_map);
        }
        return _list;
      }
      return null;
    });
  }

  /// Use filepath(fileId) as id.
  Future<ArchiveM?> getArchive(ChatMsgM chatMsgM) async {
    final archiveId = chatMsgM.msgNormal!.content;
    final archiveM = await ArchiveDao().getArchive(archiveId);
    if (archiveM != null) {
      return archiveM;
    }

    try {
      final resourceApi = ResourceApi();
      final res = await resourceApi.getArchive(archiveId);
      if (res.statusCode == 200 && res.data != null) {
        final archive = res.data!;
        final archiveM =
            ArchiveM.item(archiveId, json.encode(archive), chatMsgM.createdAt);

        await ArchiveDao().addOrUpdate(archiveM);
        return archiveM;
      } else {
        App.logger.severe("Archive fetched failed. Id: $archiveId");
      }
    } catch (e) {
      App.logger.severe("$e, archiveId: $archiveId");
    }
    return null;
  }

  Future<bool> sendForward(
      List<int> midList, List<int> uidList, List<int> gidList) async {
    String archiveId;
    try {
      final resourceApi = ResourceApi();
      archiveId = (await resourceApi.archive(midList)).data!;
    } catch (e) {
      App.logger.severe(e);
      return false;
    }

    try {
      // send archive msg.
      final localMid = uuid();

      for (final uid in uidList) {
        try {
          final userApi = UserApi();
          await userApi
              .sendArchiveMsg(uid, localMid, archiveId)
              .then((value) {});
        } catch (e) {
          App.logger.severe(e);
          return false;
        }
      }

      for (final gid in gidList) {
        try {
          final groupApi = GroupApi();
          await groupApi
              .sendArchiveMsg(gid, localMid, archiveId)
              .then((value) {});
        } catch (e) {
          App.logger.severe(e);
          return false;
        }
      }

      return true;
    } catch (e) {
      App.logger.severe(e);
      return false;
    }
  }

  Future<bool> sendArchiveForward(
      String archiveId, List<int> uidList, List<int> gidList) async {
    // send archive msg.
    final localMid = uuid();

    for (final uid in uidList) {
      try {
        final userApi = UserApi();
        await userApi.sendArchiveMsg(uid, localMid, archiveId).then((value) {});
      } catch (e) {
        App.logger.severe(e);
        return false;
      }
    }

    for (final gid in gidList) {
      try {
        final groupApi = GroupApi();
        await groupApi
            .sendArchiveMsg(gid, localMid, archiveId)
            .then((value) {});
      } catch (e) {
        App.logger.severe(e);
        return false;
      }
    }

    return true;
  }

  Future getOpenGraphicParse(url) async {
    final resourceApi = ResourceApi();
    return (await resourceApi.getOpenGraphicParse(url)).data;
  }
}
