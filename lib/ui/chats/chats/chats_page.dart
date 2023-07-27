// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/dm_info.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/event_bus_objects/private_channel_link_event.dart';
import 'package:vocechat_client/event_bus_objects/push_to_chat_event.dart';
import 'package:vocechat_client/event_bus_objects/user_change_event.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/models/ui_models/chat_page_controller.dart';
import 'package:vocechat_client/models/ui_models/chat_tile_data.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:vocechat_client/ui/chats/chat/voce_chat_page.dart';
import 'package:vocechat_client/ui/chats/chats/chats_bar.dart';
import 'package:vocechat_client/ui/chats/chats/voce_chat_tile.dart';
import 'package:vocechat_client/globals.dart' as globals;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  Offset _tapPosition = Offset.zero;

  ValueNotifier<bool> drawerOpenNotifier = ValueNotifier(false);

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
    App.app.chatService.subscribeReady(_onReady);
    globals.userSettings.addListener(_onUserSettingsChange);

    eventBus.on<UserChangeEvent>().listen((event) {
      clearChats();
      prepareChats();
      getMemberCount();

      calUnreadCountSum();

      App.app.chatService.subscribeMsg(_onMessage);
      App.app.chatService.subscribeGroups(_onChannel);
      App.app.chatService.subscribeUsers(_onUser);
      App.app.chatService.subscribeReady(_onReady);
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

    eventBus.on<PushToChatEvent>().listen((event) async {
      final chatId = SharedFuncs.getChatId(uid: event.uid, gid: event.gid);
      if (chatId == null || chatId.isEmpty) return;

      ChatTileData? chatTileData = chatTileMap[chatId];
      if (chatTileData == null) {
        if (event.uid != null) {
          final userInfoM = await UserInfoDao().getUserByUid(event.uid!);
          if (userInfoM != null) {
            chatTileData = await ChatTileData.fromUser(userInfoM);
            chatTileMap.addAll({chatId: chatTileData});
          }
        } else if (event.gid != null) {
          final groupInfoM = await GroupInfoDao().getGroupByGid(event.gid!);
          if (groupInfoM != null) {
            chatTileData = await ChatTileData.fromChannel(groupInfoM);
            chatTileMap.addAll({chatId: chatTileData});
          }
        }
      }

      if (chatTileData == null) return;

      if (!initialListDataCompleter.isCompleted) {
        await initialListDataCompleter.future.then((_) {
          onTap(chatTileData!);
        });
      } else {
        onTap(chatTileData);
      }
    });
  }

  @override
  void dispose() {
    clearChats();
    App.app.chatService.unsubscribeMsg(_onMessage);
    App.app.chatService.unsubscribeGroups(_onChannel);
    App.app.chatService.unsubscribeUsers(_onUser);
    App.app.chatService.unsubscribeReady(_onReady);
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

    return SlidableAutoCloseBehavior(
      child: ListView.separated(
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final data = sorted[index];
          return _buildChatTile(data);
        },
        separatorBuilder: (context, index) {
          return Divider(
            indent: 80,
            color: AppColors.grey200,
          );
        },
      ),
    );
  }

  Widget _buildChatTile(ChatTileData data) {
    if (Platform.isIOS) {
      const actionWidth = 95;

      List<Widget> children = [
        ValueListenableBuilder<bool>(
          valueListenable: data.isMuted,
          builder: (context, isMuted, child) {
            return SlidableAction(
                flex: 1,
                autoClose: true,
                onPressed: (context) async {
                  if (isMuted) {
                    await data.unmute();
                  } else {
                    await data.mute();
                  }
                },
                backgroundColor: Colors.blue.shade600,
                label: isMuted
                    ? AppLocalizations.of(context)!.unmute
                    : AppLocalizations.of(context)!.mute);
          },
        ),
        ValueListenableBuilder<bool>(
            valueListenable: data.isPinned,
            builder: (context, isPinned, _) {
              return SlidableAction(
                  flex: 1,
                  autoClose: true,
                  onPressed: (context) {
                    if (isPinned) {
                      data.unpin();
                    } else {
                      data.pin();
                    }
                  },
                  backgroundColor: Colors.grey.shade600,
                  label: isPinned
                      ? AppLocalizations.of(context)!.unpin
                      : AppLocalizations.of(context)!.pin);
            }),
      ];

      if (data.isUser) {
        children.add(SlidableAction(
            flex: 1,
            autoClose: true,
            onPressed: (context) {
              final dmUid = data.userInfoM!.value.uid;
              DmInfoDao().removeByDmUid(dmUid).then((value) {
                if (value > 0) {
                  chatTileMap.remove(SharedFuncs.getChatId(uid: dmUid));
                  setState(() {});
                }
              });
            },
            backgroundColor: Colors.red,
            label: AppLocalizations.of(context)!.hide));
      }

      double extentRatio =
          children.length * actionWidth / MediaQuery.of(context).size.width;
      if (extentRatio > 1) {
        extentRatio = 1;
      }

      return Slidable(
          key: ObjectKey(data),
          endActionPane: ActionPane(
              extentRatio: extentRatio,
              motion: DrawerMotion(),
              children: children),
          child: VoceChatTile(tileData: data, onTap: onTap));
    } else {
      return GestureDetector(
          onTapDown: _getTapPosition,
          onLongPress: () {
            _showContextMenu(context, data);
          },
          child: VoceChatTile(tileData: data, onTap: onTap));
    }
  }

  void _getTapPosition(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    setState(() {
      _tapPosition = referenceBox.globalToLocal(details.globalPosition);
    });
  }

  void _showContextMenu(BuildContext context, ChatTileData data) async {
    final RenderObject? overlay =
        Overlay.of(context).context.findRenderObject();

    List<PopupMenuEntry<String>> items = [
      PopupMenuItem(
        value: 'mute',
        child: Text(
          data.isMuted.value
              ? AppLocalizations.of(context)!.unmute
              : AppLocalizations.of(context)!.mute,
        ),
      ),
      PopupMenuItem(
        value: 'pin',
        child: Text(
          data.isPinned.value
              ? AppLocalizations.of(context)!.unpin
              : AppLocalizations.of(context)!.pin,
        ),
      ),
    ];
    if (data.isUser) {
      items.add(PopupMenuItem(
        value: 'hide',
        child: Text(AppLocalizations.of(context)!.hide,
            style: TextStyle(color: Colors.red)),
      ));
    }

    final result = await showMenu(
        context: context,

        // Show the context menu at the tap location
        position: RelativeRect.fromRect(
            Rect.fromLTWH(_tapPosition.dx, _tapPosition.dy, 30, 30),
            Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
                overlay.paintBounds.size.height)),

        // set a list of choices for the context menu
        items: items);

    // Implement the logic for each choice here
    switch (result) {
      case 'mute':
        if (data.isMuted.value) {
          await data.unmute();
        } else {
          await data.mute();
        }
        break;
      case 'pin':
        if (data.isPinned.value) {
          data.unpin();
        } else {
          data.pin();
        }
        break;
      case 'hide':
        final dmUid = data.userInfoM!.value.uid;
        DmInfoDao().removeByDmUid(dmUid).then((value) {
          if (value > 0) {
            chatTileMap.remove(SharedFuncs.getChatId(uid: dmUid));
            setState(() {});
          }
        });
        break;
    }
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

  Future<void> _onReady({bool clearAll = false}) async {
    if (clearAll) {
      for (final each in chatTileMap.values) {
        each.clearSnippet();
      }
    }
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

    if (mounted) {
      setState(() {});
    }
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
            if (updatedGroupInfoM != null) {
              tileData.groupInfoM!.value = updatedGroupInfoM;
            }
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
            if (updatedUserInfoM != null) {
              tileData.userInfoM!.value = updatedUserInfoM;
            }
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
