import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/models/ui_models/msg_tile_data.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/file_handler/audio_file_handler.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/voce_msg_tile.dart';

class ChatPageController {
  // What do we need?

  // 1. A list of messages
  // 2. A map of message sender's info (UserInfoM), which acts like a cache
  //    - Do we need ValueNotifiers for that?
  // 3. A map of message sender's avatar (File), which acts like a cache

  // Constructors
  ChatPageController.user(
      {required ValueNotifier<UserInfoM> this.userInfoMNotifier})
      : groupInfoMNotifier = null {
    handleSubscriptions();
  }

  ChatPageController.channel(
      {required ValueNotifier<GroupInfoM> this.groupInfoMNotifier})
      : userInfoMNotifier = null {
    handleSubscriptions();
  }

  // Message data
  final Set<String> _localMidSet = {};
  List<MsgTileData> tileDataList = [];
  final Map<int, UserInfoM> _userInfoMap = {};

  // Properties and meta data
  ValueNotifier<UserInfoM>? userInfoMNotifier;
  ValueNotifier<GroupInfoM>? groupInfoMNotifier;

  // UI variables
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  Set<VoidCallback> _scrollToBottomListeners = {};
  ValueNotifier<bool> isLoadingHistory = ValueNotifier(false);

  // Instances of tools
  final ChatMsgDao _chatMsgDao = ChatMsgDao();
  final taskQueue = TaskQueue();

  // Instances of list variables
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  final PageMeta _pageMeta = PageMeta()
    ..pageSize = defaultPageSize
    ..pageNumber = 0;

  bool get isChannel => groupInfoMNotifier != null && userInfoMNotifier == null;
  bool get isUser => groupInfoMNotifier == null && userInfoMNotifier != null;

  Future<bool> get reachesEnd async {
    bool localEnds = !_pageMeta.hasNextPage;
    bool serverEnds = true;

    if (isUser) {
      return localEnds;
    } else {
      final gid = groupInfoMNotifier!.value.gid;
      final beforeMid = await ChatMsgDao().getChannelMinMid(gid);
      final res = await GroupApi().getHistory(gid, beforeMid, limit: 25);

      if (res.statusCode != 200 ||
          (res.statusCode == 200 && (res.data as List).isEmpty)) {
        serverEnds = true;
      } else {
        if ((res.data as List).isNotEmpty) serverEnds = false;
      }
      return localEnds && serverEnds;
    }
  }

  int get count => tileDataList.length;

  void handleSubscriptions() {
    App.app.chatService.subscribeMsg(onMessage);
    App.app.chatService.subscribeMidDelete(onDeleteWithMid);
    App.app.chatService.subscribeLmidDelete(onDeleteWithLocalMid);
  }

  void handleUnsubscriptions() {
    App.app.chatService.unsubscribeMsg(onMessage);
    App.app.chatService.unsubscribeMidDelete(onDeleteWithMid);
    App.app.chatService.unsubscribeLmidDelete(onDeleteWithLocalMid);
  }

  /// Must be called after chat page is dismissed.
  void dispose() {
    handleUnsubscriptions();
    _scrollToBottomListeners.clear();
    tileDataList.clear();
    _localMidSet.clear();
    _userInfoMap.clear();
  }

  void notifyScrollToBottomListeners() {
    for (final listener in _scrollToBottomListeners) {
      listener();
    }
  }

  void addScrollToBottomListener(VoidCallback listener) {
    _scrollToBottomListeners.add(listener);
  }

  void removeScrollToBottomListener(VoidCallback listener) {
    _scrollToBottomListeners.remove(listener);
  }

  /// Prepare the data for the chat page.
  ///
  /// Includes first page of messages and the user info map.
  /// Should be called before the chat page is built, then pass into the chat page.
  Future<void> prepare() async {
    await loadHistory(enableServerHistory: false);
  }

  Future<void> updateReadIndex(int mid) async {
    if (isChannel) {
      final gid = groupInfoMNotifier!.value.gid;
      await GroupInfoDao()
          .updateProperties(gid, readIndex: mid)
          .then((groupInfoM) {
        if (groupInfoM != null) {
          App.app.chatService.fireChannel(groupInfoM, EventActions.update);
        }
        App.app.chatService.addGroupReadIndex(mid, gid);
      });
    } else if (isUser) {
      final uid = userInfoMNotifier!.value.uid;
      await UserInfoDao()
          .updateProperties(uid, readIndex: mid)
          .then((userInfoM) {
        if (userInfoM != null) {
          App.app.chatService.fireUser(userInfoM, EventActions.update);
        }
        App.app.chatService.addUserReadIndex(mid, uid);
      });
    } else {
      throw Exception('Neither channel nor user');
    }
  }

  /// Filter expired and deleted(only in server history) messages, prepare and
  /// insert valid messages into the list.
  /// Only do data-level operations, will not update UI list.
  ///
  /// Remove expired messages. For duplicated messages, substitude old with the
  /// new one. Can be only used in [prepare] due to message ordering.
  Future<List<ChatMsgM>> removeExpiredMsgs(List<ChatMsgM> msgList) async {
    final msgListCopy = List<ChatMsgM>.from(msgList);

    for (ChatMsgM chatMsgM in msgListCopy) {
      if ((await checkAndDeleteExpiredMsg(chatMsgM)) != null) {
        // not null == expired == should be removed from list.
        msgList.remove(chatMsgM);
      } else {
        // Do nothing. Do massive insert after [loadHistory] finishes.
      }
    }

    return msgList;
  }

  /// Check if the message expires. If so, delete it from db.
  ///
  /// Return the message to be deleted. If the message is valid, return null.
  Future<ChatMsgM?> checkAndDeleteExpiredMsg(ChatMsgM chatMsgM) async {
    if (await chatMsgM.expiredOrNeedsDeleting) {
      await _chatMsgDao.deleteMsgByLocalMid(chatMsgM);
      FileHandler.singleton.deleteWithChatMsgM(chatMsgM);
      AudioFileHandler().deleteWithChatMsgM(chatMsgM);
      return chatMsgM;
    } else {
      return null;
    }
  }

  /// Prepare the single [ChatMsgM] data.
  ///
  /// It calls [MsgTileData.primaryPrepare] to prepare the [tileData] with local
  /// db data.
  Future<MsgTileData> prepareTileData(ChatMsgM chatMsgM) async {
    UserInfoM? userInfoM;
    final senderUid = chatMsgM.fromUid;
    if (_userInfoMap.containsKey(senderUid)) {
      userInfoM = _userInfoMap[senderUid];
    } else {
      userInfoM = await UserInfoDao().getUserByUid(chatMsgM.fromUid);
      userInfoM ??= UserInfoM.deleted();

      _userInfoMap.addAll({senderUid: userInfoM});
    }

    final tileData = MsgTileData(chatMsgM: chatMsgM, userInfoM: userInfoM!);
    await tileData.primaryPrepare();

    return tileData;
  }

  Future<void> loadHistory({bool enableServerHistory = true}) async {
    if (isLoadingHistory.value) return;

    App.logger.info("Loading server history");

    isLoadingHistory.value = true;

    try {
      final msgList = <ChatMsgM>[];

      // Recursively load local messages first, then recursively load server
      // messages, until [msgList.length] reaches [defaultPageSize].
      await _recursivelyLoadHistory(msgList);

      // until [msgList.length] reaches [defaultPageSize], or there is no result
      // returned from server.
      // Though user api has the same history api, it makes no sense as there
      // won't be any message history before the user is created, thus there is
      // no DM history.
      if (isChannel &&
          enableServerHistory &&
          msgList.length < defaultPageSize &&
          !_pageMeta.hasNextPage) {
        await _loadServerHistory(msgList);
      }

      msgList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (msgList.isNotEmpty) {
        final maxMid = msgList.first.mid;
        await updateReadIndex(maxMid);
      }

      for (var msg in msgList) {
        final tileData = await prepareTileData(msg);
        if (_localMidSet.contains(tileData.chatMsgMNotifier.value.localMid)) {
          // duplicated
          final index = tileDataList.indexWhere((element) =>
              element.chatMsgMNotifier.value.mid ==
              tileData.chatMsgMNotifier.value.mid);
          if (index >= 0) {
            tileDataList[index] = tileData;
          }
        } else {
          insert(findInsertIndex(tileData.chatMsgMNotifier.value), tileData,
              scroll: false);
        }
      }

      App.logger.info("History message loaded, length: ${msgList.length}");
    } catch (e) {
      App.logger.severe(e);
    }

    isLoadingHistory.value = false;
  }

  Future<void> _recursivelyLoadHistory(List<ChatMsgM> msgList) async {
    PageData<ChatMsgM> pageData;
    if (isChannel) {
      pageData = await ChatMsgDao().paginateLastByGid(
          _pageMeta..pageNumber += 1, '', groupInfoMNotifier!.value.gid,
          withReactions: true);
    } else if (isUser) {
      pageData = await ChatMsgDao().paginateLastByDmUid(
          _pageMeta..pageNumber += 1, '', userInfoMNotifier!.value.uid,
          withReactions: true);
    } else {
      throw Exception('Neither channel nor user');
    }

    msgList.addAll(await removeExpiredMsgs(pageData.records.reversed.toList()));

    if (msgList.length < _pageMeta.pageSize && _pageMeta.hasNextPage) {
      _pageMeta.pageNumber -= 1;
      await _recursivelyLoadHistory(msgList);
    }
  }

  Future<void> _loadServerHistory(List<ChatMsgM> msgList) async {
    final gid = groupInfoMNotifier!.value.gid;

    await _recursivelyLoadServerHistory(msgList, gid);
  }

  Future<void> _recursivelyLoadServerHistory(
      List<ChatMsgM> msgList, int gid) async {
    final beforeMid = await ChatMsgDao().getChannelMinMid(gid);
    final res = await GroupApi().getHistory(gid, beforeMid, limit: 25);

    if (res.statusCode != 200 || res.data == null) return;

    final msgs = await App.app.chatService.handleServerHistory(res.data);
    msgList.addAll(await removeExpiredMsgs(msgs));

    if (msgList.length < defaultPageSize && msgs.isNotEmpty) {
      await _recursivelyLoadServerHistory(msgList, gid);
    }
  }

  /// Insert the [tileData] at [index].
  ///
  /// If the [tileData] is duplicated, update the [tileData] at [index].
  /// Also updates the [_localMidSet], [tileDataList] and [AnimatedList].
  ///
  /// Only called after [prepare] is called, usually when new message arrives.
  Future<void> insert(int index, MsgTileData tileData,
      {bool scroll = true}) async {
    // Check if any local messages of type reply has the same localMid as the
    // newly inserted message, if so, update the local reply message.
    for (final localTileData in tileDataList) {
      if (localTileData.chatMsgMNotifier.value.isReplyMsg &&
          localTileData.repliedMsgMNotifier.value?.localMid ==
              tileData.chatMsgMNotifier.value.localMid) {
        localTileData.repliedMsgMNotifier.value =
            tileData.chatMsgMNotifier.value;
      }
    }

    if (_localMidSet.contains(tileData.chatMsgMNotifier.value.localMid)) {
      // duplicated
      final index = tileDataList.indexWhere((element) =>
          element.chatMsgMNotifier.value.localMid ==
          tileData.chatMsgMNotifier.value.localMid);
      if (index >= 0) {
        await checkAndUpdateTileData(index, tileData);
      }
    } else {
      _localMidSet.add(tileData.chatMsgMNotifier.value.localMid);
      tileDataList.insert(index, tileData);
      listKey.currentState?.insertItem(index);

      if (scroll) {
        notifyScrollToBottomListeners();
      }
    }
  }

  /// Remove the [tileData] at [index].
  ///
  /// Also updates the [_localMidSet]. [AnimatedList] will also be updated.
  void removeAt(int index) {
    final removedItem = tileDataList.removeAt(index);
    listKey.currentState?.removeItem(
        index,
        (context, animation) =>
            _buildRemovedItem(removedItem, context, animation));
  }

  Future<void> checkAndUpdateTileData(
      int index, MsgTileData newTileData) async {
    tileDataList[index].chatMsgMNotifier.value =
        newTileData.chatMsgMNotifier.value;
    tileDataList[index].userInfoM = newTileData.userInfoM;

    await tileDataList[index].primaryPrepare();
  }

  Widget _buildRemovedItem(
      MsgTileData item, BuildContext context, Animation<double> animation) {
    return SizeTransition(
        sizeFactor: animation, child: VoceMsgTile(tileData: item));
  }

  // -- Subscriptions

  /// Handles all [chatMsgM] from [ChatService] via [onMessage] function.
  ///
  /// Includes all messages except *delete* type of *reaction* messages.
  Future<void> onMessage(ChatMsgM chatMsgM, bool afterReady,
      {bool? snippetOnly}) async {
    if (snippetOnly ?? false) return;

    // TODO: handle afterReady.

    if (isChannel && chatMsgM.gid == groupInfoMNotifier!.value.gid ||
        isUser && chatMsgM.dmUid == userInfoMNotifier!.value.uid) {
      final tileData = await prepareTileData(chatMsgM);

      taskQueue.add(() async {
        insert(findInsertIndex(chatMsgM), tileData);
      });

      await updateReadIndex(chatMsgM.mid);
    }
  }

  int findInsertIndex(ChatMsgM chatMsgM) {
    int index = 0;
    for (final tileData in tileDataList) {
      if (tileData.chatMsgMNotifier.value.createdAt > chatMsgM.createdAt) {
        index++;
      } else {
        break;
      }
    }
    return index;
  }

  /// Only handles *delete* type of *reaction* messages.
  ///
  /// Any locally initiated deletion actions should not be handled here.
  Future<void> onDeleteWithMid(int targetMid) async {
    // Check if the message deleted is also replied in another message
    for (final localTileData in tileDataList) {
      if (localTileData.chatMsgMNotifier.value.isReplyMsg &&
          localTileData.repliedMsgMNotifier.value?.mid == targetMid) {
        localTileData.repliedMsgMNotifier.value = null;
      }
    }

    final index = tileDataList.indexWhere(
        (element) => element.chatMsgMNotifier.value.mid == targetMid);
    if (index >= 0) {
      removeAt(index);
    }
  }

  Future<void> onDeleteWithLocalMid(String localMid) async {
    for (final localTileData in tileDataList) {
      if (localTileData.chatMsgMNotifier.value.isReplyMsg &&
          localTileData.repliedMsgMNotifier.value?.localMid == localMid) {
        localTileData.repliedMsgMNotifier.value = null;
      }
    }

    final index = tileDataList.indexWhere(
        (element) => element.chatMsgMNotifier.value.localMid == localMid);
    if (index >= 0) {
      removeAt(index);
    }
  }
}

typedef RemovedItemBuilder<T> = Widget Function(
    T item, BuildContext context, Animation<double> animation);
