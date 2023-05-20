import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/api/models/group/group_info.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/pinned_msg.dart';
import 'package:vocechat_client/api/models/msg/chat_msg.dart';
import 'package:vocechat_client/api/models/msg/msg_normal.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/api/models/user/user_info_update.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/dm_info.dart';
import 'package:vocechat_client/dao/init_dao/reaction.dart';
import 'package:vocechat_client/services/file_handler/audio_file_handler.dart';
import 'package:vocechat_client/services/sse/sse.dart';
import 'package:vocechat_client/services/sse/sse_queue.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/dao/init_dao/archive.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/sse/sse_event_consts.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/dao/init_dao/open_graphic_thumbnail.dart';
import 'package:vocechat_client/api/models/resource/open_graphic_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../dao/org_dao/chat_server.dart';

enum EventActions { create, delete, update }

typedef UsersAware = Future<void> Function(
    UserInfoM userInfoM, EventActions action);
typedef GroupAware = Future<void> Function(
    GroupInfoM groupInfoM, EventActions action);

typedef MsgAware = Future<void> Function(ChatMsgM chatMsgM, bool afterReady,
    {bool? snippetOnly});
typedef ReactionAware = Future<void> Function(
    ReactionM reaction, bool afterReady);

typedef MidDeleteAware = Future<void> Function(int targetMid);
typedef LocalmidDeleteAware = Future<void> Function(String localMid);
typedef UserStatusAware = Future<void> Function(int uid, bool isOnline);
typedef OrgInfoAware = Future<void> Function(ChatServerM chatServerM);

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
  final Set<OrgInfoAware> _orgInfoListeners = {};

  late SseQueue sseQueue;
  late TaskQueue mainTaskQueue;
  late Timer readIndexTimer;

  bool afterReady = false;

  final Map<int, ChatMsgM> dmInfoMap = {}; // {uid: createdAt}

  final Map<int, ChatMsgM> msgMap = {};
  final Map<int, ReactionM> reactionMap = {};

  Future<void> initContacts() async {
    if (enableContact) {
      final res = await UserApi().getUserContacts();
      if (res.statusCode == 200 && res.data != null) {
        final dao = UserInfoDao();
        final userInfoMList =
            res.data!.map((e) => UserInfoM.fromUserContact(e)).toList();
        for (final each in userInfoMList) {
          await dao.addOrUpdate(each);
        }

        final uidList = userInfoMList.map((e) => e.uid).toList();
        await dao.emptyUnpushedContactStatus(uidList);
      }
    } else {
      return;
    }
  }

  void initSse() async {
    Sse.sse.close();
    App.app.statusService?.fireSseLoading(SseStatus.connecting);

    if (App.app.userDb == null) {
      App.logger.warning("App.app.userDb null. SSE not subscribed.");
      App.app.statusService?.fireSseLoading(SseStatus.disconnected);
      return;
    }

    try {
      initContacts().then((_) => Sse.sse.connect());
    } catch (e) {
      App.logger.severe(e);
    }

    Sse.sse.subscribeSseEvent(handleSseEvent);
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

  void subscribeOrgInfoStatus(OrgInfoAware orgInfoAware) {
    unsubscribeOrgInfoStatus(orgInfoAware);
    _orgInfoListeners.add(orgInfoAware);
  }

  void unsubscribeOrgInfoStatus(OrgInfoAware orgInfoAware) {
    _orgInfoListeners.remove(orgInfoAware);
  }

  void fireUser(UserInfoM userInfoM, EventActions action) {
    if (userInfoM.uid == App.app.userDb?.uid) {
      App.app.userDb!.info = userInfoM.info;
    }
    for (UsersAware userAware in _userListeners) {
      try {
        userAware(userInfoM, action);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireChannel(GroupInfoM groupInfoM, EventActions action) {
    for (GroupAware groupAware in _groupListeners) {
      try {
        groupAware(groupInfoM, action);
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

  void fireOrgInfo(ChatServerM chatServerM) {
    for (OrgInfoAware orgInfoAware in _orgInfoListeners) {
      try {
        orgInfoAware(chatServerM);
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
          break;

        case sseHeartbeat:
          App.app.statusService?.fireSseLoading(SseStatus.successful);
          break;

        case sseChat:
        case sseGroupChanged:
        case sseJoinedGroup:
        case sseKickFromGroup:
        case ssePinnedMessageUpdated:
        case ssePinnedChats:
        case sseReady:
        case sseRelatedGroups:
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
        case ssePinnedChats:
          await _handlePinnedChats(map);
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

    if (chatMsg.mid > -1) {
      final localMsg = await ChatMsgDao().getMsgByMid(chatMsg.mid);
      if (localMsg != null && localMsg.status == MsgStatus.fail) {
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
          fireChannel(newGroupInfoM, EventActions.update);
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
        fireChannel(value, EventActions.create);
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
          fireChannel(value, EventActions.delete);
        }
      });
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handlePinnedChats(Map<String, dynamic> map) async {
    assert(map["type"] == ssePinnedChats);

    try {
      // To record pinned uids and gids,
      // compare local pinned uids and gids, take complement sets, and
      // clear the complement's [pinnedAt] property.
      List<int> ssePinnedUids = [];
      List<int> ssePinnedGids = [];

      final userInfoDao = UserInfoDao();
      final groupInfoDao = GroupInfoDao();

      final chats = map["chats"] as List<dynamic>;
      for (final chat in chats) {
        final uid = chat["target"]?["uid"] as int?;
        final gid = chat["target"]?["gid"] as int?;
        final updatedAt = chat["updated_at"] as int?;

        if (uid != null) {
          ssePinnedUids.add(uid);
          final user = await userInfoDao.getUserByUid(uid);
          if (user != null) {
            await userInfoDao.updateProperties(uid, pinnedAt: updatedAt);
          }
        } else if (gid != null) {
          ssePinnedGids.add(gid);
          final group = await groupInfoDao.getGroupByGid(gid);
          if (group != null) {
            await groupInfoDao.updateProperties(gid, pinnedAt: updatedAt);
          }
        }
      }

      await userInfoDao.emptyUnpushedPinnedStatus(ssePinnedUids);
      await groupInfoDao.emptyUnpushedPinnedStatus(ssePinnedGids);
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
            fireChannel(updatedGroupInfoM, EventActions.update);
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
          if (afterReady) {
            fireChannel(groupInfoM, EventActions.delete);
          }
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
            if (afterReady) {
              fireChannel(groupInfoM, EventActions.create);
            }
          });
        }
      }
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
          fireChannel(value, EventActions.update);
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
            fireChannel(value, EventActions.delete);
          }
        });
      } else {
        await GroupInfoDao().removeMembers(gid, uids).then((value) {
          if (value != null) {
            fireChannel(value, EventActions.update);
          }
        });
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleUsersLog(Map<String, dynamic> usersLog) async {
    assert(usersLog.containsKey("type") && usersLog["type"] == sseUsersLog);

    // try {
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
                fireUser(value, EventActions.create);
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
                  fireUser(value, EventActions.update);
                });
              }
            }
            break;
          case "delete":
            UserInfo userInfo = UserInfo.fromJson(userMap);
            UserInfoM m = UserInfoM.fromUserInfo(userInfo, "");

            await UserInfoDao()
                .removeByUid(m.uid)
                .then((value) => fireUser(m, EventActions.delete));

            if (m.uid == App.app.userDb?.uid) {
              await App.app.authService?.selfDelete();
            }

            break;
          default:
        }
        int version = userMap["log_id"];

        await UserDbMDao.dao.updateUsersVersion(App.app.userDb!.id, version);
      }
    }
    // } catch (e) {
    //   App.logger.severe(e);
    // }
  }

  Future<void> _handleUserSettings(Map<String, dynamic> map) async {
    assert(map["type"] == sseUserSettings);
    {
      // read index groups
      final readIndexGroups = map["read_index_groups"] as List?;
      if (readIndexGroups != null && readIndexGroups.isNotEmpty) {
        for (var each in readIndexGroups) {
          final mid = each["mid"];
          final gid = each["gid"];
          if (mid != null && gid != null) {
            await GroupInfoDao()
                .updateProperties(gid, readIndex: mid)
                .then((value) {
              if (value != null) {
                fireChannel(value, EventActions.update);
              }
            });
          }
        }
      }
    }
    {
      // read index users
      final readIndexUsers = map["read_index_users"] as List?;
      if (readIndexUsers != null && readIndexUsers.isNotEmpty) {
        for (var each in readIndexUsers) {
          final mid = each["mid"];
          final uid = each["uid"];
          if (mid != null && uid != null) {
            await UserInfoDao()
                .updateProperties(uid, readIndex: mid)
                .then((value) {
              if (value != null) {
                fireUser(value, EventActions.update);
              }
            });
          }
        }
      }
    }
    {
      // add / remove mute groups
      final muteGroups = map["mute_groups"] as List?;
      if (muteGroups != null && muteGroups.isNotEmpty) {
        for (var each in muteGroups) {
          final gid = each["gid"];
          if (gid != null) {
            final expiredAt = each["expired_at"] as int?;

            await GroupInfoDao()
                .updateProperties(gid,
                    enableMute: true, muteExpiresAt: expiredAt)
                .then((value) {
              if (value != null) {
                fireChannel(value, EventActions.update);
              }
            });
          }
        }
      }
    }

    {
      // add mute users
      final muteUsers = map["mute_users"] as List?;
      if (muteUsers != null && muteUsers.isNotEmpty) {
        for (var each in muteUsers) {
          final expiredAt = each["expired_at"] as int?;
          final uid = each["uid"];
          if (uid != null) {
            await UserInfoDao()
                .updateProperties(uid,
                    enableMute: true, muteExpiresAt: expiredAt)
                .then((value) {
              if (value != null) {
                fireUser(value, EventActions.update);
              }
            });
          }
        }
      } else {}
    }

    {
      // add burn_after_reading_groups
      final burnAfterReadingGroups = map["burn_after_reading_groups"] as List?;
      if (burnAfterReadingGroups != null && burnAfterReadingGroups.isNotEmpty) {
        for (var each in burnAfterReadingGroups) {
          final expiresIn = each["expires_in"] as int?;
          final gid = each["gid"];

          if (expiresIn != null && gid != null) {
            await GroupInfoDao()
                .updateProperties(gid, burnAfterReadSecond: expiresIn)
                .then((value) {
              if (value != null) {
                fireChannel(value, EventActions.update);
              }
            });
          }
        }
      }
    }

    {
      // add burn_after_reading_users
      final burnAfterReadingUsers = map["burn_after_reading_users"] as List?;
      if (burnAfterReadingUsers != null && burnAfterReadingUsers.isNotEmpty) {
        for (var each in burnAfterReadingUsers) {
          final expiresIn = each["expires_in"] as int?;
          final uid = each["uid"];

          if (expiresIn != null && uid != null) {
            await UserInfoDao()
                .updateProperties(uid, burnAfterReadSecond: expiresIn)
                .then((value) {
              if (value != null) {
                fireUser(value, EventActions.update);
              }
            });
          }
        }
      }
    }
  }

  Future<void> _handleUserSettingsChanged(Map<String, dynamic> map) async {
    assert(map['type'] == sseUserSettingsChanged);

    // read index groups
    final readIndexGroups = map["read_index_groups"] as List?;
    if (readIndexGroups != null && readIndexGroups.isNotEmpty) {
      for (var each in readIndexGroups) {
        final mid = each["mid"];
        final gid = each["gid"];
        if (mid != null && gid != null) {
          await GroupInfoDao()
              .updateProperties(gid, readIndex: mid)
              .then((value) {
            if (value != null) {
              fireChannel(value, EventActions.update);
            }
          });
        }
      }
    }

    // read index users
    final readIndexUsers = map["read_index_users"] as List?;
    if (readIndexUsers != null && readIndexUsers.isNotEmpty) {
      for (var each in readIndexUsers) {
        final mid = each["mid"];
        final uid = each["uid"];
        if (mid != null && uid != null) {
          await UserInfoDao()
              .updateProperties(uid, readIndex: mid)
              .then((value) {
            if (value != null) {
              fireUser(value, EventActions.update);
            }
          });
        }
      }
    }

    {
      // add mute groups
      final muteGroups = map["add_mute_groups"] as List?;
      if (muteGroups != null && muteGroups.isNotEmpty) {
        for (var each in muteGroups) {
          final expiredAt = each["expired_at"] as int?;
          final gid = each["gid"];
          if (gid != null) {
            await GroupInfoDao()
                .updateProperties(gid,
                    enableMute: true, muteExpiresAt: expiredAt)
                .then((value) {
              if (value != null) {
                fireChannel(value, EventActions.update);
              }
            });
          }
        }
      }
    }

    {
      // add mute users
      final muteUsers = map["add_mute_users"] as List?;
      if (muteUsers != null && muteUsers.isNotEmpty) {
        for (var each in muteUsers) {
          final expiredAt = each["expired_at"] as int?;
          final uid = each["uid"];
          if (uid != null) {
            await UserInfoDao()
                .updateProperties(uid,
                    enableMute: true, muteExpiresAt: expiredAt)
                .then((value) {
              if (value != null) {
                fireUser(value, EventActions.update);
              }
            });
          }
        }
      }
    }

    {
      // remove mute groups
      final muteGroups = map["remove_mute_groups"] as List?;
      if (muteGroups != null && muteGroups.isNotEmpty) {
        for (var gid in muteGroups) {
          if (gid != null) {
            GroupInfoDao()
                .updateProperties(gid, enableMute: false, muteExpiresAt: null)
                .then((value) {
              if (value != null) {
                fireChannel(value, EventActions.update);
              }
            });
          }
        }
      }
    }

    {
      // remove mute users
      final muteUsers = map["remove_mute_users"] as List?;
      if (muteUsers != null && muteUsers.isNotEmpty) {
        for (var uid in muteUsers) {
          if (uid != null) {
            await UserInfoDao()
                .updateProperties(uid, enableMute: false, muteExpiresAt: null)
                .then((value) {
              if (value != null) {
                fireUser(value, EventActions.update);
              }
            });
          }
        }
      }
    }

    {
      // add burn_after_reading_groups
      final burnAfterReadingGroups = map["burn_after_reading_groups"] as List?;
      if (burnAfterReadingGroups != null && burnAfterReadingGroups.isNotEmpty) {
        for (var each in burnAfterReadingGroups) {
          final expiresIn = each["expires_in"] as int?;
          final gid = each["gid"];

          if (expiresIn != null && gid != null) {
            await GroupInfoDao()
                .updateProperties(gid, burnAfterReadSecond: expiresIn)
                .then((value) {
              if (value != null) {
                fireChannel(value, EventActions.update);
              }
            });
          }
        }
      }
    }

    {
      // add burn_after_reading_users
      final burnAfterReadingUsers = map["burn_after_reading_users"] as List?;
      if (burnAfterReadingUsers != null && burnAfterReadingUsers.isNotEmpty) {
        for (var each in burnAfterReadingUsers) {
          final expiresIn = each["expires_in"] as int?;
          final uid = each["uid"];

          if (expiresIn != null && uid != null) {
            await UserInfoDao()
                .updateProperties(uid, burnAfterReadSecond: expiresIn)
                .then((value) {
              if (value != null) {
                fireUser(value, EventActions.update);
              }
            });
          }
        }
      }
    }

    {
      // handle "add_contacts"
      // final addContacts = map["add_contacts"] as List?;
      // if (addContacts != null && addContacts.isNotEmpty) {
      //   final dao = UserInfoDao();
      //   for (var contact in addContacts) {
      //     final contactInfo = ContactInfo.fromJson(contact["info"]);
      //     final targetUid = contact["target_uid"] as int;
      //     await dao
      //         .updateContactInfo(targetUid,
      //             status: contactInfo.status,
      //             contactCreatedAt: contactInfo.createdAt,
      //             contactUpdatedAt: contactInfo.updatedAt)
      //         .then((value) {
      //       if (value != null) {
      //         fireUser(value, EventActions.update);
      //       }
      //     });
      //   }
      // }
    }

    {
      // handle "remove_contacts"
      // final removeContacts = map["remove_contacts"] as List?;
      // if (removeContacts != null) {
      //   final dao = UserInfoDao();
      //   for (final uid in removeContacts) {
      //     await dao.updateContactInfo((uid as int), status: "").then((value) {
      //       if (value != null) {
      //         fireUser(value, EventActions.update);
      //       }
      //     });
      //   }
      // }
    }

    {
      // handle "add_pin_chats"
      final addPinChats = map["add_pin_chats"] as List?;
      if (addPinChats != null) {
        final userInfoDao = UserInfoDao();
        final groupInfoDao = GroupInfoDao();
        for (final chat in addPinChats) {
          final uid = chat["target"]?["uid"] as int?;
          final gid = chat["target"]?["gid"] as int?;
          final updatedAt = chat["updated_at"] as int?;

          if (uid != null) {
            await userInfoDao
                .updateProperties(uid, pinnedAt: updatedAt)
                .then((value) {
              if (value != null) {
                fireUser(value, EventActions.update);
              }
            });
          } else if (gid != null) {
            await groupInfoDao
                .updateProperties(gid, pinnedAt: updatedAt)
                .then((value) {
              if (value != null) {
                fireChannel(value, EventActions.update);
              }
            });
          }
        }
      }
    }

    {
      // handle "remove_pin_chats"
      final removePinChats = map["remove_pin_chats"] as List?;
      if (removePinChats != null) {
        final userInfoDao = UserInfoDao();
        final groupInfoDao = GroupInfoDao();
        for (final data in removePinChats) {
          final uid = data["uid"] as int?;
          final gid = data["gid"] as int?;
          const updatedAt = -1;

          if (uid != null) {
            await userInfoDao
                .updateProperties(uid, pinnedAt: updatedAt)
                .then((value) {
              if (value != null) {
                fireUser(value, EventActions.update);
              }
            });
          } else if (gid != null) {
            await groupInfoDao
                .updateProperties(gid, pinnedAt: updatedAt)
                .then((value) {
              if (value != null) {
                fireChannel(value, EventActions.update);
              }
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
      cumulateMsg(chatMsgM);
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

  Future<void> mute(
      {int? gid, int? uid, bool unmute = false, int? expiredAt}) async {
    Map<String, dynamic> map = {};

    if (gid != null) {
      if (unmute) {
        map = {
          "remove_mute_groups": [gid]
        };
      } else {
        map = {
          "add_mute_groups": [
            {"expired_at": expiredAt, "gid": gid}
          ]
        };
      }
    } else if (uid != null) {
      if (unmute) {
        map = {
          "remove_mute_users": [uid]
        };
      } else {
        map = {
          "add_mute_users": [
            {"expired_at": expiredAt, "uid": uid}
          ]
        };
      }
    }
    map.addAll({"type": 'user_settings_changed'});

    if (map.isNotEmpty) {
      _handleUserSettingsChanged(map);
    }
  }

  Future getOpenGraphicParse(url) async {
    final resourceApi = ResourceApi();
    return (await resourceApi.getOpenGraphicParse(url)).data;
  }
}
