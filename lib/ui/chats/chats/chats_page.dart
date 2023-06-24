// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/dm_info.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/event_bus_objects/private_channel_link_event.dart';
import 'package:vocechat_client/event_bus_objects/user_change_event.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/models/ui_models/chat_page_controller.dart';
import 'package:vocechat_client/models/ui_models/chat_tile_data.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:vocechat_client/ui/chats/chat/voce_chat_page.dart';
import 'package:vocechat_client/ui/chats/chats/chats_bar.dart';
import 'package:vocechat_client/ui/chats/chats/voce_chat_tile.dart';
import 'package:vocechat_client/globals.dart' as globals;

class ChatsPage extends StatefulWidget {
  static const route = "/chats/chats";

  const ChatsPage({Key? key}) : super(key: key);

  // ignore: library_private_types_in_public_api
  static _ChatsPageState? of(BuildContext context) =>
      context.findAncestorStateOfType<_ChatsPageState>();

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage>
    with AutomaticKeepAliveClientMixin<ChatsPage> {
  TaskQueue taskQueue = TaskQueue(enableStatusDisplay: true);

  ValueNotifier<int> memberCountNotifier = ValueNotifier(0);

  final Map<String, ChatTileData> chatTileMap = {};

  Completer<void> initialListDataCompleter = Completer();

  int count = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    prepareChats();
    getMemberCount();
    calUnreadCountSum();

    App.app.chatService.subscribeMsg(_onMessage);
    App.app.chatService.subscribeGroups(_onChannel);
    App.app.chatService.subscribeUsers(_onUser);
    App.app.chatService.subscribeRefresh(_onRefresh);
    globals.userSettings.addListener(_onUserSettingsChange);

    eventBus.on<UserChangeEvent>().listen((event) {
      clearChats();
      prepareChats();
      getMemberCount();

      calUnreadCountSum();

      App.app.chatService.subscribeMsg(_onMessage);
      App.app.chatService.subscribeGroups(_onChannel);
      App.app.chatService.subscribeUsers(_onUser);
      App.app.chatService.subscribeRefresh(_onRefresh);
      globals.userSettings.addListener(_onUserSettingsChange);
    });

    // test
    // final url =
    //     "https://privoce.voce.chat/invite_private/226?magic_token=8e2d6785ddbccad5e61cefdb48ac8d98bc4c5c15dff84a2aba1bc35f1d469f4202000000e200000000000000060000000000000034303438333496e97a6400000000";
    // final uri = Uri.parse(url);
    // handleInvitationLink(uri);

    eventBus.on<PrivateChannelInvitationLinkEvent>().listen((event) {
      handleInvitationLink(event.uri);
    });
  }

  @override
  void dispose() {
    clearChats();
    App.app.chatService.unsubscribeMsg(_onMessage);
    App.app.chatService.unsubscribeGroups(_onChannel);
    App.app.chatService.unsubscribeUsers(_onUser);
    App.app.chatService.unsubscribeRefresh(_onRefresh);
    globals.userSettings.removeListener(_onUserSettingsChange);
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
        onCreateChannel: (groupInfoM) async {
          final tileData = await ChatTileData.fromChannel(groupInfoM);
          final chatId = SharedFuncs.getChatId(gid: groupInfoM.gid);
          if (chatId != null) {
            chatTileMap.addAll({chatId: tileData});
            onTap(tileData);
          }
        },
        onCreateDm: (userInfoM) async {
          final tileData = await ChatTileData.fromUser(userInfoM);
          final chatId = SharedFuncs.getChatId(uid: userInfoM.uid);
          if (chatId != null) {
            chatTileMap.addAll({chatId: tileData});
            onTap(tileData);
          }
        },
      ),
      body: _buildChats(),
    );
  }

  Widget _buildChats() {
    final List<ChatTileData> pinned = [];
    final List<ChatTileData> unpinned = [];

    for (var tileData in chatTileMap.values) {
      if (tileData.pinnedAt > 0) {
        pinned.add(tileData);
      } else {
        unpinned.add(tileData);
      }
    }

    pinned.sort((a, b) {
      if (a.pinnedAt != b.pinnedAt) {
        return b.pinnedAt - a.pinnedAt;
      } else {
        return b.updatedAt.value - a.updatedAt.value;
      }
    });

    unpinned.sort((a, b) => b.updatedAt.value - a.updatedAt.value);

    final sorted = [...pinned, ...unpinned];

    return ListView.separated(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        return VoceChatTile(
            key: ObjectKey(sorted[index]),
            tileData: sorted[index],
            onTap: onTap);
      },
      separatorBuilder: (context, index) {
        return Divider(
          indent: 80,
          color: AppColors.grey200,
        );
      },
    );
  }

  /// [VoceChatService] Message listener
  ///
  /// Only do its work when [afterReady] is true.
  Future<void> _onMessage(ChatMsgM chatMsgM, bool afterReady,
      {bool? snippetOnly}) async {
    if (!afterReady) return;

    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId != null && chatTileMap.containsKey(chatId)) {
      await chatTileMap[chatId]?.updateByChatMsg(chatMsgM);
    } else {
      // if no current chat session, create a new one
      final tileData = await ChatTileData.fromChatMsgM(chatMsgM);
      final chatId =
          SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
      if (chatId != null && tileData != null) {
        chatTileMap.addAll({chatId: tileData});
      }

      // Only work when [afterReady] is true.
      await DmInfoDao()
          .addOrUpdate(DmInfoM.item(chatMsgM.dmUid, "", chatMsgM.createdAt));
    }

    calUnreadCountSum();

    if (mounted) {
      setState(() {});
    }
  }

  void _onRefresh() {
    prepareChats();
  }

  Future<void> _onChannel(
      GroupInfoM groupInfoM, EventActions action, bool afterReady) async {
    final chatId = SharedFuncs.getChatId(gid: groupInfoM.gid);

    switch (action) {
      case EventActions.create:
      case EventActions.update:
        if (chatId != null) {
          if (!chatTileMap.containsKey(chatId)) {
            final tileData = await ChatTileData.fromChannel(groupInfoM);
            chatTileMap.addAll({chatId: tileData});
          } else {
            await chatTileMap[chatId]?.setChannel(groupInfoM: groupInfoM);
          }
        }
        break;
      case EventActions.delete:
        if (chatId != null) {
          chatTileMap.remove(chatId);
        }
        break;
      default:
    }

    calUnreadCountSum();

    if (afterReady) {
      setState(() {});
    }
  }

  Future<void> _onUser(
      UserInfoM userInfoM, EventActions action, bool afterReady) async {
    final chatId = SharedFuncs.getChatId(uid: userInfoM.uid);

    switch (action) {
      case EventActions.create:
        break;
      case EventActions.update:
        if (chatId != null) {
          if (!chatTileMap.containsKey(chatId)) {
            final tileData = await ChatTileData.fromUser(userInfoM);
            chatTileMap.addAll({chatId: tileData});
          } else {
            await chatTileMap[chatId]?.setUser(userInfoM: userInfoM);
          }
        }
        break;
      case EventActions.delete:
        if (chatId != null) {
          chatTileMap.remove(chatId);
        }
        break;
      default:
    }

    calUnreadCountSum();
    getMemberCount();

    if (afterReady) {
      setState(() {});
    }
  }

  void _onUserSettingsChange() async {
    for (final chat in chatTileMap.values) {
      if (chat.isChannel) {
        await chat.setChannel();
      } else {
        await chat.setUser();
      }
    }

    setState(() {});
  }

  void clearChats() {
    chatTileMap.clear();
  }

  Future<void> prepareChats() async {
    await prepareChannels();
    await prepareDms();
    calUnreadCountSum();
    if (mounted) {
      setState(() {});
    }

    if (!initialListDataCompleter.isCompleted) {
      initialListDataCompleter.complete();
    }
  }

  void onTap(ChatTileData tileData) async {
    if (tileData.isChannel) {
      GlobalKey<AppMentionsState> mentionsKey = GlobalKey<AppMentionsState>();
      ChatPageController controller =
          ChatPageController.channel(groupInfoMNotifier: tileData.groupInfoM!);
      controller.prepare().then((value) {
        final unreadCount = tileData.unreadCount.value;
        unreadCountSum.value -= unreadCount;
        Navigator.push(
            context,
            MaterialPageRoute<String?>(
                builder: (context) => VoceChatPage.channel(
                    mentionsKey: mentionsKey,
                    controller: controller))).then((value) async {
          final draft = mentionsKey.currentState?.controller?.text.trim();

          GroupInfoDao()
              .updateProperties(tileData.groupInfoM!.value.gid, draft: draft)
              .then((updatedGroupInfoM) {
            tileData.draft.value = draft ?? "";
          });

          calUnreadCountSum();
          controller.dispose();
        });
      });
    } else {
      GlobalKey<AppMentionsState> mentionsKey = GlobalKey<AppMentionsState>();

      ChatPageController controller =
          ChatPageController.user(userInfoMNotifier: tileData.userInfoM!);

      controller.prepare().then((value) {
        final unreadCount = tileData.unreadCount.value;
        unreadCountSum.value -= unreadCount;
        Navigator.push(
            context,
            MaterialPageRoute<String?>(
                builder: (context) => VoceChatPage.user(
                    mentionsKey: mentionsKey,
                    controller: controller))).then((value) async {
          final draft = mentionsKey.currentState?.controller?.text.trim();

          await UserInfoDao()
              .updateProperties(tileData.userInfoM!.value.uid, draft: draft)
              .then((updatedUserInfoM) {
            tileData.draft.value = draft ?? "";
          });

          calUnreadCountSum();
          controller.dispose();
        });
      });
    }
  }

  Future<void> prepareChannels() async {
    final groupList = await GroupInfoDao().getAllGroupList();

    if (groupList != null) {
      for (GroupInfoM groupInfoM in groupList) {
        final channelTileData = await ChatTileData.fromChannel(groupInfoM);
        final chatId = SharedFuncs.getChatId(gid: groupInfoM.gid);

        if (chatId != null) {
          chatTileMap.addAll({chatId: channelTileData});
        }
      }
    }
  }

  Future<void> prepareDms() async {
    final dmList = await DmInfoDao().getDmList();
    if (dmList == null) return;

    for (final dm in dmList) {
      final dmTileData = await ChatTileData.fromUid(dm.dmUid);
      final chatId = SharedFuncs.getChatId(uid: dm.dmUid);
      if (chatId != null && dmTileData != null) {
        chatTileMap.addAll({chatId: dmTileData});
      }
    }
  }

  void getMemberCount() async {
    final memberCount = (await UserInfoDao().getUserList())?.length;
    if (memberCount != null) {
      memberCountNotifier.value = memberCount;
    }
  }

  void calUnreadCountSum() {
    int count = 0;
    for (var element in chatTileMap.values) {
      if (!element.isMuted.value) {
        count += element.unreadCount.value;
      }
    }
    unreadCountSum.value = count;
  }

  void handleInvitationLink(Uri uri) async {
    final pathSegments = uri.pathSegments;

    if (pathSegments.length < 2) {
      return;
    }

    if (pathSegments[0] == 'invite_private') {
      final gid = int.tryParse(pathSegments[1]);
      final magicToken = uri.queryParameters['magic_token'];

      if (gid == null || magicToken == null || magicToken.isEmpty) return;

      if (!initialListDataCompleter.isCompleted) {
        await initialListDataCompleter.future.then((_) {
          pushToChannel(gid, magicToken);
        });
      } else {
        pushToChannel(gid, magicToken);
      }
    }
  }

  void pushToChannel(int gid, String magicToken) async {
    final chatId = SharedFuncs.getChatId(gid: gid);
    if (chatId == null) return;

    if (chatTileMap.containsKey(chatId)) {
      onTap(chatTileMap[chatId]!);
    } else {
      final groupInfoM = await GroupInfoDao().getGroupByGid(gid);
      if (groupInfoM != null) {
        final tileData = await ChatTileData.fromChannel(groupInfoM);
        final chatId = SharedFuncs.getChatId(gid: groupInfoM.gid);
        chatTileMap.addAll({chatId!: tileData});
      } else {
        await GroupInfoDao().getGroupByGid(gid).then((groupInfoM) async {
          if (groupInfoM != null) {
            return;
          } else {
            await UserApi()
                .joinPrivateChannel(magicToken)
                .then((response) async {
              if (response.statusCode == 200 && response.data != null) {
                App.logger.info("joinPrivateChannel success, gid: $gid");
                await GroupInfoDao()
                    .addOrUpdate(GroupInfoM.fromGroupInfo(response.data!, true))
                    .then((value) async {
                  await prepareChats().then((_) {
                    final chatId = SharedFuncs.getChatId(gid: gid);
                    if (chatId != null) {
                      onTap(chatTileMap[chatId]!);
                    }
                  });
                });
              } else {
                App.logger.severe("joinPrivateChannel failed, gid: $gid");
              }
            });
          }
        });
      }
    }
  }
}
