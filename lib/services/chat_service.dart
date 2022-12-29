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
import 'package:vocechat_client/app_alert_dialog.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/archive.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/sse.dart';
import 'package:vocechat_client/services/sse_event/sse_event_consts.dart';
import 'package:vocechat_client/services/sse_queue.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/dao/init_dao/open_graphic_thumbnail.dart';
import 'package:vocechat_client/api/models/resource/open_graphic_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum EventActions { create, delete, update }

enum ReactionTypes { edit, like, delete }

typedef UsersAware = Future<void> Function(
    UserInfoM userInfoM, EventActions action, bool ready);
typedef GroupAware = Future<void> Function(
    GroupInfoM groupInfoM, EventActions action, bool ready);
typedef MsgAware = Future<void> Function(
    ChatMsgM chatMsgM, String localMid, dynamic data, bool ready);
typedef ReactionAware = Future<void>
    Function(ReactionTypes reaction, int mid, bool ready, [ChatMsgM? content]);
typedef SnippetAware = Future<void> Function(ChatMsgM chatMsgM, bool ready);
typedef UserStatusAware = Future<void> Function(
    int uid, bool isOnline, bool ready);

class ChatService {
  ChatService() {
    setReadIndexTimer();

    sseQueue = SseQueue(
        closure: handleSseStream,
        afterTaskCheck: () async {
          fireReady();
        });
    taskQueue = TaskQueue();
  }

  void dispose() {
    taskQueue.cancel();
    sseQueue.clear();
    readIndexTimer.cancel();
    Sse.sse.close();

    _afterReady = false;
  }

  final Set<UsersAware> _userListeners = {};
  final Set<GroupAware> _groupListeners = {};
  final Set<MsgAware> _normalMsgListeners = {};
  final Set<ReactionAware> _reactionListeners = {};
  final Set<VoidCallback> _readyListeners = {};
  final Set<SnippetAware> _snippetListeners = {};
  final Set<UserStatusAware> _userStatusListeners = {};

  late SseQueue sseQueue;
  late TaskQueue taskQueue;
  late Timer readIndexTimer;

  /// Used to avoid duplicated messages.
  final Set<int> midSet = {};

  /// Whether SSE has received 'ready' message.
  ///
  /// 'Ready' message means backend has pushed all accumulated messages.
  bool _afterReady = false;

  void initSse() async {
    _afterReady = false;
    Sse.sse.close();
    App.app.statusService.fireSseLoading(SseStatus.connecting);

    if (App.app.userDb == null) {
      App.logger.warning("App.app.userDb null. SSE not subscribed.");
      App.app.statusService.fireSseLoading(SseStatus.disconnected);
      return;
    }

    try {
      Sse.sse.connect();
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
    readIndexTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      // Also detects

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
        final userApi = UserApi(App.app.chatServerM.fullUrl);
        final res = await userApi.updateReadIndex(json.encode(readIndexMap));
        if (res.statusCode == 200) {
          readIndexUser.clear();
          readIndexGroup.clear();
        }
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
    _normalMsgListeners.add(msgAware);
  }

  void unsubscribeMsg(MsgAware msgAware) {
    _normalMsgListeners.remove(msgAware);
  }

  void subscribeReaction(ReactionAware reactionAware) {
    unsubscribeReaction(reactionAware);
    _reactionListeners.add(reactionAware);
  }

  void unsubscribeReaction(ReactionAware reactionAware) {
    _reactionListeners.remove(reactionAware);
  }

  void subscribeReady(VoidCallback readyAware) {
    unsubscribeReady(readyAware);
    _readyListeners.add(readyAware);
  }

  void unsubscribeReady(VoidCallback readyAware) {
    _reactionListeners.remove(readyAware);
  }

  void subscribeSnippet(SnippetAware snippetAware) {
    unsubscribeSnippet(snippetAware);
    _snippetListeners.add(snippetAware);
  }

  void unsubscribeSnippet(SnippetAware snippetAware) {
    _snippetListeners.remove(snippetAware);
  }

  void subscribeUserStatus(UserStatusAware statusAware) {
    unsubscribeUserStatus(statusAware);
    _userStatusListeners.add(statusAware);
  }

  void unsubscribeUserStatus(UserStatusAware statusAware) {
    _userStatusListeners.remove(statusAware);
  }

  void fireUser(UserInfoM userInfoM, EventActions action) {
    if (userInfoM.uid == App.app.userDb?.uid) {
      App.app.userDb!.info = userInfoM.info;
    }
    for (UsersAware userAware in _userListeners) {
      try {
        userAware(userInfoM, action, _afterReady);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireChannel(GroupInfoM groupInfoM, EventActions action) {
    for (GroupAware groupAware in _groupListeners) {
      try {
        groupAware(groupInfoM, action, _afterReady);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireMsg(ChatMsgM chatMsgM, String localMid, dynamic data) {
    for (MsgAware msgAware in _normalMsgListeners) {
      try {
        msgAware(chatMsgM, localMid, data, _afterReady);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireReaction(ReactionTypes reaction, int mid, [ChatMsgM? chatMsgM]) {
    for (ReactionAware reactionAware in _reactionListeners) {
      try {
        reactionAware(reaction, mid, _afterReady, chatMsgM);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireReady() {
    for (VoidCallback readyAware in _readyListeners) {
      try {
        readyAware();
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireSnippet(ChatMsgM chatMsgM) {
    for (SnippetAware snippetAware in _snippetListeners) {
      try {
        snippetAware(chatMsgM, _afterReady);
      } catch (e) {
        App.logger.severe(e);
      }
    }
  }

  void fireUserStatus(int uid, bool isOnline) {
    for (UserStatusAware statusAware in _userStatusListeners) {
      try {
        statusAware(uid, isOnline, _afterReady);
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
          App.app.statusService.fireTokenLoading(TokenStatus.unauthorized);

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
          App.app.statusService.fireSseLoading(SseStatus.successful);
          break;

        case sseChat:
        case sseGroupChanged:
        case sseJoinedGroup:
        case sseKickFromGroup:
        case ssePinnedMessageUpdated:
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

    // Do filtering if SSE pushes duplicated messages.
    // (Due to SSE reconnection error.)
    if (chatMsg.mid < 0) {
      return;
    }

    final msg = await ChatMsgDao().getMsgByMid(chatMsg.mid);
    if (msg != null && msg.status == MsgSendStatus.success.name) {
      return;
    }

    if (midSet.contains(chatMsg.mid)) return;

    midSet.add(chatMsg.mid);

    // Update max_mid in UserDB
    await UserDbMDao.dao.updateMaxMid(App.app.userDb!.id, chatMsg.mid);

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

  Future<void> handleHistoryChatMsg(Map<String, dynamic> chatJson) async {
    ChatMsg chatMsg = ChatMsg.fromJson(chatJson);

    // Do filtering if SSE pushes duplicated messages.
    // (Due to SSE reconnection error.)
    if (chatMsg.mid < 0) {
      return;
    }

    final msg = await ChatMsgDao().getMsgByMid(chatMsg.mid);
    if (msg != null && msg.status == MsgSendStatus.success.name) {
      return;
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

  Future<void> _handleGroupChanged(Map<String, dynamic> map) async {
    assert(map["type"] == sseGroupChanged);

    try {
      await GroupInfoDao()
          .updateGroup(map["gid"],
              description: map["description"],
              name: map["name"],
              owner: map["owner"],
              avatarUpdatedAt: map["avatar_updated_at"],
              isPublic: map["is_public"])
          .then((value) async {
        if (value == null) return;
        fireChannel(value, EventActions.update);

        if (map["avatar_updated_at"] != null && map["avatar_updated_at"] != 0) {
          final avatarUpdatedAt = map["avatar_updated_at"] as int;
          final gid = map["gid"]!;
          if (value.groupInfo.avatarUpdatedAt != avatarUpdatedAt) {
            await getGroupAvatar(gid);
          }
        }
      });
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

      final oldAvatarUpdatedAt =
          (await GroupInfoDao().getGroupByGid(groupInfoM.gid))
              ?.groupInfo
              .avatarUpdatedAt;

      await GroupInfoDao().addOrUpdate(groupInfoM).then((value) async {
        fireChannel(value, EventActions.create);
        if (shouldGetChannelAvatar(
            oldAvatarUpdatedAt, groupInfo.avatarUpdatedAt, groupInfoM.avatar)) {
          await getGroupAvatar(groupInfo.gid);
        }
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
          .then((value) {
        if (value != null) fireChannel(value, EventActions.update);
      });
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleReady() async {
    App.app.statusService.fireSseLoading(SseStatus.successful);

    _afterReady = true;

    // find DMs with draft and fire user to chats page.
    final usersWithDraft = await UserInfoDao().getUsersWithDraft();
    if (usersWithDraft == null) {
      fireReady();
      return;
    }

    for (var userInfoM in usersWithDraft) {
      fireUser(userInfoM, EventActions.create);
    }

    fireReady();
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
              .deleteChatDirectory(getChatId(gid: localGid)!);
          await ChatMsgDao().deleteMsgByGid(localGid);
          await GroupInfoDao().deleteGroupByGid(localGid);

          final groupInfoM = GroupInfoM()..gid = localGid;
          fireChannel(groupInfoM, EventActions.delete);
        }
      }

      // Update all existing groups.
      for (var groupInfo in groups) {
        if (!enablePublicChannels && groupInfo.isPublic) {
          continue;
        }

        GroupInfoM groupInfoM = GroupInfoM.fromGroupInfo(groupInfo, true);

        final oldAvatarUpdatedAt =
            (await GroupInfoDao().getGroupByGid(groupInfoM.gid))
                ?.groupInfo
                .avatarUpdatedAt;

        await GroupInfoDao().addOrUpdate(groupInfoM).then((value) async {
          fireChannel(groupInfoM, EventActions.create);
          if (shouldGetChannelAvatar(oldAvatarUpdatedAt,
              groupInfo.avatarUpdatedAt, groupInfoM.avatar)) {
            await getGroupAvatar(groupInfo.gid);
          }
        });
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  /// Check if needs to fetch channel avatar from server.
  bool shouldGetChannelAvatar(int? prev, int curr, Uint8List? currBytes) {
    // ints are [avatarUpdatedAt]

    // No local avatar but server has a new one.
    final a = ((prev == null || prev == 0) && curr != 0);

    // Has local avatar but server has a new one.
    final b = (prev != null && prev != curr);

    // Server has a new one but no local avatar data.
    final c = (curr != 0 && (currBytes == null || currBytes.isEmpty));

    // print(
    //     "prev: $prev \t curr: $curr \t currBytes: ${currBytes == null || currBytes.isEmpty} \t a: $a \t b: $b \t c: $c");

    return a || b || c;
  }

  Future<void> getGroupAvatar(int gid) async {
    try {
      final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
      final res = await resourceApi.getGroupAvatar(gid);
      if (res != null &&
          res.statusCode == 200 &&
          res.data != null &&
          res.data!.isNotEmpty) {
        await GroupInfoDao()
            .updateAvatar(gid, res.data!)
            .then((value) => fireChannel(value!, EventActions.update));
      }
    } catch (e) {
      App.logger.warning(e);
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
        await FileHandler.singleton.deleteChatDirectory(getChatId(gid: gid)!);
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
    final List<dynamic> logMaps = usersLog["logs"];
    if (logMaps.isNotEmpty) {
      for (var logMap in logMaps) {
        String action = logMap["action"];

        switch (action) {
          case "create":
            UserInfo userInfo = UserInfo.fromJson(logMap);
            UserInfoM m = UserInfoM.fromUserInfo(userInfo, Uint8List(0), "");

            await UserInfoDao()
                .addOrUpdate(m)
                .then((value) => fireUser(value, EventActions.create));
            await UserDbMDao.dao.updateUserInfo(userInfo);

            if (userInfo.avatarUpdatedAt != 0) {
              final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
              final avatarRes = await resourceApi.getUserAvatar(m.uid);
              if (avatarRes.statusCode == 200 && avatarRes.data != null) {
                App.logger.info("UID ${m.uid} Avatar obtained");
                m.avatarBytes = avatarRes.data!;

                await UserInfoDao()
                    .addOrUpdate(m)
                    .then((value) => fireUser(value, EventActions.update));
                await UserDbMDao.dao.updateUserInfo(userInfo, avatarRes.data!);
                if (m.uid == App.app.userDb?.uid) {
                  App.app.userDb?.avatarBytes = avatarRes.data!;
                  await UserDbMDao.dao.addOrUpdate(App.app.userDb!);
                }
              } else {
                App.logger.warning("UID ${m.uid} Avatar null");
              }
            }

            break;
          case "update":
            UserInfoUpdate update = UserInfoUpdate.fromJson(logMap);
            final old = await UserInfoDao().getUserByUid(update.uid);
            if (old != null) {
              final oldInfo = UserInfo.fromJson(json.decode(old.info));
              final newInfo = UserInfo.getUpdated(oldInfo, update);
              final m = UserInfoM.fromUserInfo(newInfo, Uint8List(0), "");

              await UserInfoDao()
                  .addOrUpdate(m)
                  .then((value) => fireUser(value, EventActions.update));
              await UserDbMDao.dao.updateUserInfo(newInfo);

              if (newInfo.avatarUpdatedAt != 0 &&
                  update.avatarUpdatedAt != null) {
                final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
                final avatarRes = await resourceApi.getUserAvatar(m.uid);
                if (avatarRes.statusCode == 200 && avatarRes.data != null) {
                  App.logger.info("UID ${m.uid} Avatar obtained.");
                  m.avatarBytes = avatarRes.data!;

                  await UserInfoDao()
                      .addOrUpdate(m)
                      .then((value) => fireUser(value, EventActions.update));
                  await UserDbMDao.dao.updateUserInfo(newInfo, avatarRes.data!);
                  if (m.uid == App.app.userDb?.uid) {
                    App.app.userDb?.avatarBytes = avatarRes.data!;
                    await UserDbMDao.dao.addOrUpdate(App.app.userDb!);
                  }
                } else {
                  App.logger.warning("UID ${m.uid} Avatar null");
                }
              }
            }
            break;
          case "delete":
            UserInfo userInfo = UserInfo.fromJson(logMap);
            UserInfoM m = UserInfoM.fromUserInfo(userInfo, Uint8List(0), "");

            await UserInfoDao()
                .removeByUid(m.uid)
                .then((value) => fireUser(m, EventActions.delete));

            if (m.uid == App.app.userDb?.uid) {
              await App.app.authService?.selfDelete();

              // Sorry, your account has been deleted.
              // delete
              // App.app.authService?.logout();
              // navigatorKey.currentState!
              //     .pushNamedAndRemoveUntil(ServerPage.route, (route) => false);
            }

            break;
          default:
        }
        int version = logMap["log_id"];

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
  }

  Future<void> _handleUsersSnapshot(Map<String, dynamic> usersSnapshot) async {
    assert(usersSnapshot.containsKey("type") &&
        usersSnapshot["type"] == sseUsersSnapshot);

    try {
      final List<dynamic> userMaps = usersSnapshot["users"];

      // add users to db
      if (userMaps.isNotEmpty) {
        for (var userMap in userMaps) {
          UserInfo userInfo = UserInfo.fromJson(userMap);
          UserInfoM m = UserInfoM.fromUserInfo(userInfo, Uint8List(0), "");

          await UserInfoDao()
              .addOrUpdate(m)
              .then((value) => fireUser(value, EventActions.create));
          await UserDbMDao.dao.updateUserInfo(userInfo);

          if (userInfo.avatarUpdatedAt != 0) {
            final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
            resourceApi.getUserAvatar(m.uid).then((avatarRes) async {
              App.logger.info("UID ${m.uid} Avatar obtained.");
              if (avatarRes.statusCode == 200 && avatarRes.data != null) {
                m.avatarBytes = avatarRes.data!;
                await UserInfoDao()
                    .addOrUpdate(m)
                    .then((value) => fireUser(value, EventActions.update));
                await UserDbMDao.dao.updateUserInfo(userInfo, avatarRes.data!);

                if (m.uid == App.app.userDb?.uid) {
                  App.app.userDb?.avatarBytes = avatarRes.data!;
                  await UserDbMDao.dao.addOrUpdate(App.app.userDb!);
                }
              } else {
                App.logger.warning("UID ${m.uid} Avatar null");
              }
            });
          }
        }
      }

      final int version = usersSnapshot["version"];

      await UserDbMDao.dao
          .updateUsersVersion(App.app.userDb!.id, version)
          .then((value) => App.app.userDb?.usersVersion = version);
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

          App.app.onlineStatusMap.addAll({uid: isOnline});

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

      App.app.onlineStatusMap.addAll({uid: isOnline});

      fireUserStatus(uid, isOnline);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleMsgNormal(ChatMsg chatMsg) async {
    final detail = MsgNormal.fromJson(chatMsg.detail);
    final isSelf = chatMsg.fromUid == App.app.userDb!.uid;

    String localMid;
    if (isSelf) {
      localMid = detail.properties?['cid'] ?? uuid();
    } else {
      localMid = uuid();
    }

    try {
      ChatMsgM chatMsgM;

      switch (detail.contentType) {
        case typeText:
          ChatMsg c = ChatMsg(
              target: chatMsg.target,
              mid: chatMsg.mid,
              fromUid: chatMsg.fromUid,
              createdAt: chatMsg.createdAt,
              detail: detail.toJson());
          chatMsgM = ChatMsgM.fromMsg(c, localMid, MsgSendStatus.success);
          taskQueue
              .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) async {
                    String s = value.msgNormal?.content ??
                        value.msgReply?.content ??
                        "";
                    fireSnippet(value);
                    fireMsg(value, localMid, s);
                    midSet.remove(value.mid);
                  }));

          break;
        case typeMarkdown:
          ChatMsg c = ChatMsg(
              target: chatMsg.target,
              mid: chatMsg.mid,
              fromUid: chatMsg.fromUid,
              createdAt: chatMsg.createdAt,
              detail: detail.toJson());
          chatMsgM = ChatMsgM.fromMsg(c, localMid, MsgSendStatus.success);

          taskQueue.add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
                fireSnippet(value);
                fireMsg(value, localMid, detail.content);
                midSet.remove(value.mid);
              }));

          break;

        case typeFile:
          ChatMsg c = ChatMsg(
              target: chatMsg.target,
              mid: chatMsg.mid,
              fromUid: chatMsg.fromUid,
              createdAt: chatMsg.createdAt,
              detail: detail.toJson());
          chatMsgM = ChatMsgM.fromMsg(c, localMid, MsgSendStatus.success);
          taskQueue.add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
                fireSnippet(chatMsgM);
                midSet.remove(value.mid);
              }));

          // thumb will only be downloaded if file is an image.
          try {
            if (chatMsgM.isImageMsg) {
              taskQueue.add(() =>
                  FileHandler.singleton.getImageThumb(chatMsgM).then((thumb) {
                    if (thumb != null) {
                      fireMsg(chatMsgM, chatMsgM.localMid, thumb);
                    } else {
                      fireMsg(chatMsgM, localMid, null);
                    }
                  }));
            } else {
              fireMsg(chatMsgM, localMid, null);
            }
          } catch (e) {
            App.logger.severe(e);
          }

          break;

        case typeArchive:
          ChatMsg c = ChatMsg(
              target: chatMsg.target,
              mid: chatMsg.mid,
              fromUid: chatMsg.fromUid,
              createdAt: chatMsg.createdAt,
              detail: detail.toJson());
          chatMsgM = ChatMsgM.fromMsg(c, localMid, MsgSendStatus.success);

          taskQueue
              .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) async {
                    fireSnippet(value);
                    midSet.remove(value.mid);
                  }));

          getArchive(chatMsgM).catchError((e) {
            App.logger.severe(e);
          }).then((value) {
            if (value != null) {
              fireMsg(chatMsgM, localMid, value.archive);
            } else {
              fireMsg(chatMsgM, localMid, null);
            }
          });
          break;
        default:
          break;
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  Future<void> _handleMsgReaction(ChatMsg chatMsg) async {
    final msgReactionJson = chatMsg.detail;
    final targetMid = msgReactionJson["mid"]!;

    assert(msgReactionJson["type"] == "reaction");

    try {
      final detailJson = msgReactionJson["detail"] as Map<String, dynamic>;

      switch (detailJson["type"]) {
        case "edit":
          final edit = detailJson["content"] as String;

          await ChatMsgDao()
              .editMsgByMid(targetMid, edit, MsgSendStatus.success)
              .then((newMsgM) {
            if (newMsgM != null) {
              fireSnippet(newMsgM);
              fireReaction(ReactionTypes.edit, targetMid, newMsgM);
              midSet.remove(newMsgM.mid);
            }
          });

          break;
        case "like":
          final reaction = detailJson["action"] as String;

          await ChatMsgDao()
              .reactMsgByMid(targetMid, chatMsg.fromUid, reaction,
                  DateTime.now().millisecondsSinceEpoch)
              .then((newMsgM) {
            if (newMsgM != null) {
              fireReaction(ReactionTypes.like, targetMid, newMsgM);
              midSet.remove(newMsgM.mid);
            }
          });

          break;
        case "delete":
          final int? targetMid = chatMsg.detail["mid"];
          if (targetMid == null) return;

          final targetMsgM = await ChatMsgDao().getMsgByMid(targetMid);
          if (targetMsgM == null) return;

          await ChatMsgDao().deleteMsgByMid(targetMsgM).then((mid) async {
            if (mid < 0) {
              return;
            }

            FileHandler.singleton.deleteWithChatMsgM(targetMsgM);
            fireReaction(ReactionTypes.delete, mid);

            // delete without remaining hint words in msg list.
            if (targetMsgM.isGroupMsg) {
              final curMaxMid =
                  await ChatMsgDao().getChannelMaxMid(targetMsgM.gid);
              if (curMaxMid > -1) {
                final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

                if (msg != null) {
                  fireSnippet(msg);
                  midSet.remove(msg.mid);
                }
              }
            } else {
              final curMaxMid =
                  await ChatMsgDao().getDmMaxMid(targetMsgM.dmUid);
              if (curMaxMid > -1) {
                final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

                if (msg != null) {
                  fireSnippet(msg);
                  midSet.remove(msg.mid);
                }
              }
            }
          });
          break;

        default:
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
      chatMsg.createdAt = chatMsg.createdAt;
      ChatMsgM chatMsgM =
          ChatMsgM.fromReply(chatMsg, localMid, MsgSendStatus.success);
      taskQueue
          .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) async {
                fireSnippet(value);
                fireMsg(value, localMid, msgReplyJson['content']);
                midSet.remove(value.mid);
              }));
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
        final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
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
      final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
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
      final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
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
          final userApi = UserApi(App.app.chatServerM.fullUrl);
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
          final groupApi = GroupApi(App.app.chatServerM.fullUrl);
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
        final userApi = UserApi(App.app.chatServerM.fullUrl);
        await userApi.sendArchiveMsg(uid, localMid, archiveId).then((value) {});
      } catch (e) {
        App.logger.severe(e);
        return false;
      }
    }

    for (final gid in gidList) {
      try {
        final groupApi = GroupApi(App.app.chatServerM.fullUrl);
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
    final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
    return (await resourceApi.getOpenGraphicParse(url)).data;
  }
}
