import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/event_bus_objects/user_change_event.dart';
import 'package:vocechat_client/globals.dart' as globals;
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/archive.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/dm_info.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/models/ui_models/ui_chat.dart';
import 'package:vocechat_client/models/ui_models/ui_msg.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/ui/chats/chat/chat_page.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:vocechat_client/ui/chats/chats/chats_bar.dart';
import 'package:vocechat_client/ui/chats/chats/chat_tile.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/channel_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatsPage extends StatefulWidget {
  static const route = "/chats/chats";

  const ChatsPage({Key? key}) : super(key: key);

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage>
    with AutomaticKeepAliveClientMixin<ChatsPage> {
  final List<UiChat> _uiChats = [];
  final Map<int, UserInfoM> _userInfoMap = {};

  TaskQueue taskQueue = TaskQueue(enableStatusDisplay: true);

  ValueNotifier<int> memberCountNotifier = ValueNotifier(0);

  int count = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    prepareChats();
    getMemberCount();
    globals.unreadCountSum.value = calUnreadCountSum();
    App.app.chatService.subscribeGroups(_onChannel);
    App.app.chatService.subscribeSnippet(_onSnippet);
    App.app.chatService.subscribeUsers(_onUser);
    App.app.chatService.subscribeUserStatus(_onUserStatus);
    App.app.chatService.subscribeReady(_onReady);

    eventBus.on<UserChangeEvent>().listen((event) {
      clearChats();
      prepareChats();
      getMemberCount();
    });
  }

  @override
  void dispose() {
    App.app.chatService.unsubscribeGroups(_onChannel);
    App.app.chatService.unsubscribeSnippet(_onSnippet);
    App.app.chatService.unsubscribeUsers(_onUser);
    App.app.chatService.unsubscribeUserStatus(_onUserStatus);
    App.app.chatService.unsubscribeReady(_onReady);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatsBar(
        memberCountNotifier: memberCountNotifier,
        showDrawer: () => Scaffold.of(context).openDrawer(),
        onCreateChannel: (groupInfoM) {
          final uiChat = UiChat(
              avatar: groupInfoM.avatar,
              title: groupInfoM.groupInfo.name,
              gid: groupInfoM.gid,
              isPrivateChannel: !groupInfoM.groupInfo.isPublic,
              isMuted: groupInfoM.properties.enableMute,
              updatedAt: groupInfoM.updatedAt);

          addOrReplaceChannel(uiChat);

          _onTapChannel(groupInfoM.gid);
        },
        onCreateDm: (userInfoM) {
          _onTapDm(userInfoM.uid);
        },
      ),
      body: _buildChats(),
    );
  }

  int getUiChatIndex({int? gid, int? uid}) {
    (_uiChats.map((e) => e.gid));
    int index = -1;
    if (gid != null) {
      index = _uiChats.indexWhere((element) => element.gid == gid);
    } else if (uid != null) {
      index = _uiChats.indexWhere((element) => element.uid == uid);
    }

    return index;
  }

  /// Should use inside setState method to get UI updated.
  void addOrReplaceChannel(UiChat uiChat, [int insertAt = 0]) {
    assert(uiChat.gid != null);

    int idx = _uiChats.indexWhere((element) => element.gid == uiChat.gid);
    if (idx > -1) {
      _uiChats.removeAt(idx);
    }
    _uiChats.insert(insertAt, uiChat);
  }

  /// Should use inside setState method to get UI updated.
  void addOrReplaceDm(UiChat uiChat, [int insertAt = 0]) {
    assert(uiChat.uid != null);

    int idx = _uiChats.indexWhere((element) => element.uid == uiChat.uid);
    if (idx > -1) {
      _uiChats.removeAt(idx);
    }
    _uiChats.insert(insertAt, uiChat);
  }

  Widget _buildChats() {
    _uiChats.sort(((a, b) => b.updatedAt.value.compareTo(a.updatedAt.value)));

    return ListView.separated(
      itemCount: _uiChats.length,
      itemBuilder: (context, index) {
        final uiChat = _uiChats[index];
        if (uiChat.isChannel) {
          return _buildChannelTile(uiChat);
        } else {
          return _buildDmTile(uiChat);
        }
      },
      separatorBuilder: (context, index) {
        return Divider(indent: 80);
      },
    );
  }

  Widget _buildChannelTile(UiChat uiChat) {
    assert(uiChat.gid != null);

    final avatar = ValueListenableBuilder<String>(
        valueListenable: uiChat.title,
        builder: (context, title, _) {
          return ValueListenableBuilder<Uint8List>(
              valueListenable: uiChat.avatar,
              builder: (context, avatarBytes, _) {
                return ChannelAvatar(
                  avatarSize: AvatarSize.s48,
                  avatarBytes: avatarBytes,
                  name: title,
                );
              });
        });

    return ChatTile(
        onTap: () => _onTapChannel(uiChat.gid!),
        name: uiChat.title,
        snippet: uiChat.snippet,
        updatedAt: uiChat.updatedAt,
        isMuted: uiChat.isMuted,
        draft: uiChat.draft,
        unreadCount: uiChat.unreadCount,
        unreadMentionCount: uiChat.unreadMentionCount,
        isPrivateChannel: uiChat.isPrivateChannel,
        avatar: avatar);
  }

  Widget _buildDmTile(UiChat uiChat) {
    assert(uiChat.uid != null && uiChat.onlineNotifier != null);

    Widget avatar = ValueListenableBuilder<String>(
        valueListenable: uiChat.title,
        builder: (context, title, _) {
          return ValueListenableBuilder<Uint8List>(
              valueListenable: uiChat.avatar,
              builder: (context, avatarBytes, _) {
                return UserAvatar(
                  avatarSize: AvatarSize.s48,
                  isSelf: App.app.isSelf(uiChat.uid),
                  name: title,
                  uid: uiChat.uid!,
                  avatarBytes: avatarBytes,
                  enableOnlineStatus: true,
                );
              });
        });

    return Slidable(
      endActionPane:
          ActionPane(extentRatio: 0.2, motion: DrawerMotion(), children: [
        SlidableAction(
          flex: 1,
          onPressed: (context) {
            _onDeleteDm(uiChat.uid!);
          },
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          label: 'Hide',
        ),
      ]),
      child: ChatTile(
          onTap: () => _onTapDm(uiChat.uid!),
          name: uiChat.title,
          snippet: uiChat.snippet,
          draft: uiChat.draft,
          isMuted: uiChat.isMuted,
          updatedAt: uiChat.updatedAt,
          unreadCount: uiChat.unreadCount,
          unreadMentionCount: uiChat.unreadMentionCount,
          avatar: avatar),
    );
  }

  void _onDeleteDm(int dmUid) async {
    try {
      await DmInfoDao().removeByDmUid(dmUid);

      final index = getUiChatIndex(uid: dmUid);
      if (index > -1) _uiChats.removeAt(index);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      App.logger.severe(e);
    }
  }

  void _onTapChannel(int gid) async {
    final groupInfoM = (await GroupInfoDao().getGroupByGid(gid))!;

    final groupInfo = groupInfoM.groupInfo;

    final hintText =
        AppLocalizations.of(context)!.chatTextFieldHint + " #${groupInfo.name}";
    final msgCount = await ChatMsgDao().getChatMsgCount(gid: gid);
    final draft = groupInfoM.properties.draft;

    GlobalKey<AppMentionsState> mentionsKey = GlobalKey<AppMentionsState>();
    int unreadCount = await ChatMsgDao().getGroupUnreadCount(gid);
    Navigator.push(
        context,
        MaterialPageRoute<String?>(
          builder: (context) => ChatPage(
              mentionsKey: mentionsKey,
              title: groupInfo.name,
              hintText: hintText,
              draft: draft,
              msgCount: msgCount,
              groupInfoNotifier: ValueNotifier(groupInfoM),
              unreadCount: unreadCount),
        )).then((_) async {
      final index = getUiChatIndex(gid: gid);
      if (index > -1) {
        final unreadCount = await ChatMsgDao().getGroupUnreadCount(gid);
        final unreadMentionCount =
            await ChatMsgDao().getGroupUnreadMentionCount(gid);

        _uiChats[index].unreadCount.value = unreadCount;
        _uiChats[index].unreadMentionCount.value = unreadMentionCount;

        globals.unreadCountSum.value = calUnreadCountSum();
      }

      final draft = mentionsKey.currentState?.controller?.text.trim();

      await GroupInfoDao().updateProperties(gid, draft: draft).then((value) {
        if (value != null) {
          App.app.chatService.fireChannel(value, EventActions.update);
        }
      });
    });
  }

  void _onTapDm(int dmUid) async {
    final userInfoM = (await UserInfoDao().getUserByUid(dmUid))!;

    final hintText = AppLocalizations.of(context)!.chatTextFieldHint +
        " @${userInfoM.userInfo.name}";
    final draft = userInfoM.properties.draft;
    final msgCount = await ChatMsgDao().getChatMsgCount(uid: dmUid);
    GlobalKey<AppMentionsState> mentionsKey = GlobalKey<AppMentionsState>();
    int unreadCount = await ChatMsgDao().getDmUnreadCount(dmUid);
    Navigator.push(
        context,
        MaterialPageRoute<String?>(
          builder: (context) => ChatPage(
              mentionsKey: mentionsKey,
              title: userInfoM.userInfo.name,
              msgCount: msgCount,
              hintText: hintText,
              draft: draft,
              userInfoNotifier: ValueNotifier(userInfoM),
              unreadCount: unreadCount),
        )).then((_) async {
      final index = getUiChatIndex(uid: dmUid);
      if (index > -1) {
        final unreadCount = await ChatMsgDao().getDmUnreadCount(dmUid);

        _uiChats[index].unreadCount.value = unreadCount;
        globals.unreadCountSum.value = calUnreadCountSum();
      }

      final draft = mentionsKey.currentState?.controller?.text.trim();

      UserInfoDao().updateProperties(dmUid, draft: draft).then((value) async {
        if (value != null) {
          if ((await DmInfoDao().getDmInfo(value.uid)) != null) {
            App.app.chatService.fireUser(value, EventActions.update);
          } else {
            App.app.chatService.fireUser(value, EventActions.create);
          }
        }
      });
    });
  }

  Future<void> _onChannel(GroupInfoM groupInfoM, EventActions action) async {
    taskQueue.add(() async {
      switch (action) {
        case EventActions.create:
        case EventActions.update:
          final index = getUiChatIndex(gid: groupInfoM.gid);

          if (index > -1) {
            _uiChats[index].avatar.value = groupInfoM.avatar;
            _uiChats[index].title.value = groupInfoM.groupInfo.name;
            _uiChats[index].isMuted.value = groupInfoM.properties.enableMute;
            _uiChats[index].draft.value = groupInfoM.properties.draft;
          } else {
            final uiChat = UiChat(
                avatar: groupInfoM.avatar,
                title: groupInfoM.groupInfo.name,
                gid: groupInfoM.gid,
                isPrivateChannel: !groupInfoM.groupInfo.isPublic,
                isMuted: groupInfoM.properties.enableMute,
                updatedAt: groupInfoM.updatedAt);

            addOrReplaceChannel(uiChat);
          }
          break;

        case EventActions.delete:
          final index = getUiChatIndex(gid: groupInfoM.gid);
          if (index > -1) {
            _uiChats.removeAt(index);
          }
          break;
        default:
      }
    });
  }

  /// Only response to update and delete. User initiazed in [onSnippet].
  Future<void> _onUser(UserInfoM userInfoM, EventActions action) async {
    taskQueue.add(() async {
      _userInfoMap.addAll({userInfoM.uid: userInfoM});

      final index = getUiChatIndex(uid: userInfoM.uid);

      switch (action) {
        case EventActions.create:
          if (userInfoM.properties.draft.isEmpty) {
            break;
          }
          final localMid =
              await ChatMsgDao().getLatestLocalMidInDm(userInfoM.uid);
          final latestMsgM = await ChatMsgDao().getMsgBylocalMid(localMid);
          int updatedAt =
              latestMsgM?.createdAt ?? DateTime.now().millisecondsSinceEpoch;
          String snippet =
              latestMsgM != null ? _processSnippet(latestMsgM) : "";

          final uiChat = UiChat(
              avatar: userInfoM.avatarBytes,
              title: userInfoM.userInfo.name,
              uid: userInfoM.uid,
              isMuted: userInfoM.properties.enableMute,
              onlineNotifier: ValueNotifier(false),
              snippet: snippet,
              updatedAt: updatedAt,
              draft: userInfoM.properties.draft);

          addOrReplaceDm(uiChat);

          break;
        case EventActions.update:
          if (index > -1) {
            _uiChats[index].avatar.value = userInfoM.avatarBytes;
            _uiChats[index].title.value = userInfoM.userInfo.name;
            _uiChats[index].isMuted.value = userInfoM.properties.enableMute;
            _uiChats[index].draft.value = userInfoM.properties.draft;
          }

          break;
        case EventActions.delete:
          final index = getUiChatIndex(uid: userInfoM.uid);
          if (index > -1) {
            _uiChats.removeAt(index);
          }
          break;
        default:
      }

      getMemberCount();
    });
  }

  Future<void> _onSnippet(ChatMsgM chatMsgM) async {
    taskQueue.add(() async {
      final uid = chatMsgM.isGroupMsg ? chatMsgM.fromUid : chatMsgM.dmUid;

      final userInfoM = await UserInfoDao().getUserByUid(uid);
      if (userInfoM == null) {
        App.logger.warning("No UserInfo found. uid: $uid");
      }

      String snippet = _processSnippet(chatMsgM);

      if (chatMsgM.isGroupMsg) {
        final groupInfoM = await GroupInfoDao().getGroupByGid(chatMsgM.gid);

        if (userInfoM != null && groupInfoM != null) {
          final maxMid = await ChatMsgDao().getChannelMaxMid(groupInfoM.gid);
          if (maxMid != -1 && chatMsgM.mid < maxMid) {
            return;
          }

          // Prepare snippet.
          String s = await parseMention(snippet);
          if (userInfoM.userInfo.uid == App.app.userDb!.uid) {
            s = "you: " + s;
          } else {
            s = "${userInfoM.userInfo.name}: $s";
          }

          final unreadCount =
              await ChatMsgDao().getGroupUnreadCount(chatMsgM.gid);
          final unreadMentionCount =
              await ChatMsgDao().getGroupUnreadMentionCount(chatMsgM.gid);

          final index = getUiChatIndex(gid: chatMsgM.gid);
          if (index > -1) {
            // setState(() {
            _uiChats[index].snippet.value = s;
            _uiChats[index].updatedAt.value = chatMsgM.createdAt;
            _uiChats[index].unreadCount.value = unreadCount;
            _uiChats[index].unreadMentionCount.value = unreadMentionCount;
            // });
          } else {
            // Target channel not shown in chats list.
          }
          await GroupInfoDao()
              .updateLastLocalMidBy(chatMsgM.gid, chatMsgM.localMid);
        }
      } else {
        if (userInfoM != null) {
          final maxMid = await ChatMsgDao().getDmMaxMid(userInfoM.uid);
          if (chatMsgM.edited == 1 && maxMid != -1 && chatMsgM.mid < maxMid) {
            return;
          }

          final unreadCount =
              await ChatMsgDao().getDmUnreadCount(userInfoM.uid);

          final index = getUiChatIndex(uid: uid);
          if (index > -1) {
            // setState(() {
            _uiChats[index].snippet.value = snippet;
            _uiChats[index].updatedAt.value = chatMsgM.createdAt;
            _uiChats[index].unreadCount.value = unreadCount;
            // });
          } else {
            final uiChat = UiChat(
                uid: uid,
                avatar: userInfoM.avatarBytes,
                title: userInfoM.userInfo.name,
                snippet: snippet,
                updatedAt: chatMsgM.createdAt,
                unreadCount: unreadCount,
                onlineNotifier: ValueNotifier(false));
            // setState(() {
            addOrReplaceDm(uiChat);
            // });
          }
          DmInfoDao().addOrReplace(DmInfoM.item(
              chatMsgM.dmUid, chatMsgM.localMid, chatMsgM.createdAt));
        }
      }
      globals.unreadCountSum.value = calUnreadCountSum();
    });
  }

  String _processSnippet(ChatMsgM chatMsgM) {
    String snippet;

    switch (chatMsgM.type) {
      case MsgDetailType.normal:
        switch (chatMsgM.detailType) {
          case MsgContentType.text:
            snippet =
                chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? "";
            break;
          case MsgContentType.markdown:
            snippet = "[Markdown]" +
                (chatMsgM.msgNormal?.content ??
                    chatMsgM.msgReply?.content ??
                    "");

            break;
          case MsgContentType.file:
            final name = chatMsgM.msgNormal?.properties?["name"] ?? "";

            if (chatMsgM.isImageMsg) {
              snippet = "[Image] $name";
            } else {
              snippet = "[File] $name";
            }
            break;
          case MsgContentType.archive:
            snippet = "[Archive]";
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
            snippet = "Unsupported Message Type";
        }
        break;
      case MsgDetailType.reply:
        switch (chatMsgM.detailType) {
          case MsgContentType.text:
            snippet =
                chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? "";
            break;
          case MsgContentType.markdown:
            snippet = "[Markdown]" +
                (chatMsgM.msgNormal?.content ??
                    chatMsgM.msgReply?.content ??
                    "");

            break;
          default:
            snippet = "Unsupported Message Type";
            break;
        }
        break;
      default:
        snippet = "Unsupported Message Type";
    }
    return snippet;
  }

  Future<void> _onUserStatus(int uid, bool isOnline) async {
    final index = getUiChatIndex(uid: uid);
    if (index > -1) {
      _uiChats[index].onlineNotifier?.value = isOnline;
    }
  }

  void _onReady() {
    taskQueue.add(() async {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void clearChats() {
    _uiChats.clear();
  }

  Future<void> prepareChats() async {
    await prepareChannels();
    await prepareDms();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> prepareChannels() async {
    final groupList = await GroupInfoDao().getAllGroupList();

    if (groupList != null) {
      for (GroupInfoM groupInfoM in groupList) {
        final localMid =
            await ChatMsgDao().getLatestLocalMidInGroup(groupInfoM.gid);
        final latestMsgM = await ChatMsgDao().getMsgBylocalMid(localMid);
        final unreadCount =
            await ChatMsgDao().getGroupUnreadCount(groupInfoM.gid);
        final unreadMentionCount =
            await ChatMsgDao().getGroupUnreadMentionCount(groupInfoM.gid);
        final draft = groupInfoM.properties.draft;

        if (latestMsgM != null) {
          String s = await parseMention(_processSnippet(latestMsgM));

          final userInfoM =
              await UserInfoDao().getUserByUid(latestMsgM.fromUid);
          if (userInfoM != null) {
            if (userInfoM.uid == App.app.userDb!.uid) {
              s = "you: " + s;
            } else {
              s = userInfoM.userInfo.name + ": " + s;
            }
          }

          final uiChat = UiChat(
            avatar: groupInfoM.avatar,
            title: groupInfoM.groupInfo.name,
            snippet: s,
            unreadMentionCount: unreadMentionCount,
            draft: draft,
            gid: groupInfoM.gid,
            updatedAt: latestMsgM.createdAt,
            isPrivateChannel: !groupInfoM.groupInfo.isPublic,
            unreadCount: unreadCount,
          );

          addOrReplaceChannel(uiChat);
        } else {
          final uiChat = UiChat(
              avatar: groupInfoM.avatar,
              title: groupInfoM.groupInfo.name,
              gid: groupInfoM.gid,
              updatedAt: groupInfoM.createdAt,
              isPrivateChannel: !groupInfoM.groupInfo.isPublic);

          addOrReplaceChannel(uiChat);
        }
      }
      // setState(() {
      globals.unreadCountSum.value = calUnreadCountSum();
      // });
    }
  }

  Future<void> prepareDms() async {
    final dmList = await DmInfoDao().getDmList();

    if (dmList != null && dmList.isNotEmpty) {
      for (final dm in dmList) {
        final userInfoM = await UserInfoDao().getUserByUid(dm.dmUid);
        if (userInfoM != null) {
          _userInfoMap.addAll({userInfoM.uid: userInfoM});
          userInfoM.onlineNotifier.value =
              App.app.onlineStatusMap[userInfoM.uid] ?? false;

          final latestMsgM =
              await ChatMsgDao().getMsgBylocalMid(dm.lastLocalMid);
          final unreadCount =
              await ChatMsgDao().getDmUnreadCount(userInfoM.uid);
          final draft = userInfoM.properties.draft;

          if (latestMsgM != null) {
            String s = _processSnippet(latestMsgM);

            final uiChat = UiChat(
                avatar: userInfoM.avatarBytes,
                title: userInfoM.userInfo.name,
                uid: userInfoM.uid,
                snippet: s,
                draft: draft,
                unreadCount: unreadCount,
                updatedAt: latestMsgM.createdAt,
                onlineNotifier: ValueNotifier(false));

            addOrReplaceDm(uiChat);
          } else {
            final uiChat = UiChat(
                avatar: userInfoM.avatarBytes,
                title: userInfoM.userInfo.name,
                uid: userInfoM.uid,
                onlineNotifier: ValueNotifier(false));

            addOrReplaceDm(uiChat);
          }
        } else {
          App.logger.warning("Can't find userInfo in ui. uid: ${dm.dmUid}");
        }
      }
      // setState(() {
      globals.unreadCountSum.value = calUnreadCountSum();
      // });
    }
  }

  void getMemberCount() async {
    final memberCount = (await UserInfoDao().getUserList())?.length;
    if (memberCount != null) {
      memberCountNotifier.value = memberCount;
    }
  }

  int calUnreadCountSum() {
    int count = 0;
    for (var element in _uiChats) {
      count += element.unreadCount.value;
    }
    return count;
  }
}
