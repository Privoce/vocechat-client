// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/lib/message_api.dart';
import 'package:vocechat_client/api/lib/saved_api.dart';
import 'package:vocechat_client/mixins/orientation_mixins.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/send_service.dart';
import 'package:vocechat_client/services/send_task_queue/send_task_queue.dart';
import 'package:vocechat_client/services/sse/sse_event_consts.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/message_tile.dart';
import 'package:vocechat_client/ui/chats/chat/msg_actions/msg_action_sheet.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/dao/init_dao/archive.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/chat_bar.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/chat_textfield.dart';
import 'package:vocechat_client/models/ui_models/ui_msg.dart';
import 'package:vocechat_client/ui/chats/chat/msg_actions/msg_action_tile.dart';
import 'package:vocechat_client/globals.dart' as globals;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/ui/widgets/chat_selection_sheet.dart';

// ignore: must_be_immutable
class ChatPage extends StatefulWidget {
  static const route = "chats/chat";

  final String title;
  final String? description;
  final String hintText;
  String? draft;

  /// The total number of messages in the channel chat.
  /// Only available for channels. Used to show ChannelStart widget.
  // int msgCount;

  ValueNotifier<GroupInfoM>? groupInfoNotifier;
  ValueNotifier<UserInfoM>? userInfoNotifier;
  GlobalKey<AppMentionsState> mentionsKey;

  late final bool _isGroup;

  final FocusNode _focusNode = FocusNode();
  final int unreadCount;
  ChatPage(
      {Key? key,
      required this.title,
      this.description,
      required this.hintText,
      this.draft,
      // required this.msgCount,
      required this.mentionsKey,
      this.groupInfoNotifier,
      this.userInfoNotifier,
      required this.unreadCount})
      : super(key: key) {
    assert((groupInfoNotifier == null) ^ (userInfoNotifier == null));
    if (groupInfoNotifier == null) {
      _isGroup = false;
    } else {
      _isGroup = true;
    }
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
// with PortraitStatefulModeMixin<ChatPage>
{
  final PageMeta _pageMeta = PageMeta()
    ..pageSize = defaultPageSize
    ..pageNumber = 0;

  bool _isLoadingHistory = false;
  late int _initReadIndex;

  final Map<int, UserInfoM> _userInfoMMap = {};
  final List<UiMsg> _uiMsgList = [];
  final Set<String> _localMidSet = {};

  ChatMsgM? repliedMsgM;
  UserInfoM? repliedUserInfoM;
  File? repliedImageFile;

  // actions
  final ValueNotifier<SendType> _sendTypeNotifier =
      ValueNotifier(SendType.normal);
  final ValueNotifier<bool> isSelecting = ValueNotifier(false);
  final ValueNotifier<List<ChatMsgM>> selectedMsgMList = ValueNotifier([]);
  final ValueNotifier<bool> selectedMsgCantMultipleArchive =
      ValueNotifier(false);
  ChatMsgM? _editingMsgM;

  set setEditingMsgM(editingMsgM) {
    _editingMsgM = editingMsgM;
  }

  final taskQueue = TaskQueue(enableStatusDisplay: false);

  double progressPercent = 0;
  final scrollDirection = Axis.vertical;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();

    //init scroll
    _scrollController = AutoScrollController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: scrollDirection);

    if (widget._isGroup) {
      _initReadIndex = widget.groupInfoNotifier!.value.properties.readIndex;
    } else {
      _initReadIndex = widget.userInfoNotifier!.value.properties.readIndex;
    }

    App.app.chatService.subscribeMsg(_onMsg);
    App.app.chatService.subscribeReaction(_onReaction);
    App.app.chatService.subscribeUsers(_onUser);
    App.app.chatService.subscribeGroups(_onGroup);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadHistory();
      }
    });
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    App.app.chatService.unsubscribeMsg(_onMsg);
    App.app.chatService.unsubscribeReaction(_onReaction);
    App.app.chatService.unsubscribeUsers(_onUser);
    App.app.chatService.unsubscribeGroups(_onGroup);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatBar(
        groupInfoNotifier: widget.groupInfoNotifier,
        userInfoNotifier: widget.userInfoNotifier,
        unreadCount: globals.unreadCountSum,
        onPop: () {
          Navigator.of(context).pop();
        },
      ),
      body: GestureDetector(
        onTap: () {
          return FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(child: _buildMsgList()),
            ValueListenableBuilder<bool>(
              valueListenable: isSelecting,
              builder: (context, isSelecting, _) {
                if (!isSelecting) {
                  return _buildTextField();
                } else {
                  return _buildSelectionBottomBar();
                }
              },
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildSelectionBottomBar() {
    return SizedBox(
        height: 56,
        width: double.maxFinite,
        child: Stack(
          children: [
            Center(
              child: ValueListenableBuilder<bool>(
                  valueListenable: selectedMsgCantMultipleArchive,
                  builder: (context, canArchive, _) {
                    Widget child;
                    if (canArchive) {
                      child = Row(
                          key: ValueKey<int>(0),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(AppLocalizations.of(context)!
                                    .chatPageSelectionWarning),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 32),
                              child: _buildIcon(
                                  Icon(
                                    AppIcons.delete,
                                    color: AppColors.errorRed,
                                  ),
                                  () => _batchDelete()),
                            )
                          ]);
                    } else {
                      child = Row(
                          key: ValueKey<int>(1),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildIcon(
                                Icon(AppIcons.forward,
                                    color: AppColors.grey600),
                                () => _forward()),
                            _buildIcon(
                                Icon(AppIcons.bookmark,
                                    color: AppColors.grey600),
                                () => _createSavedItem()),
                            _buildIcon(
                                Icon(
                                  AppIcons.delete,
                                  color: AppColors.errorRed,
                                ),
                                () => _batchDelete())
                          ]);
                    }
                    return child;
                  }),
            ),
            Container(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        selectedMsgMList.value = [];
                        isSelecting.value = false;
                      });
                    }
                  },
                  child: Icon(AppIcons.close_circle,
                      size: 16, color: AppColors.grey600)),
            )
          ],
        ));
  }

  Widget _buildIcon(Icon icon, Function()? onPressed, {Color? color}) {
    return Container(
        decoration: BoxDecoration(
            color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
        width: 40,
        height: 40,
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Center(
          child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              child: icon,
              color: color),
        ));
  }

  ChatTextField _buildTextField() {
    return ChatTextField(
      focusNode: widget._focusNode,
      mentionsKey: widget.mentionsKey,
      draft: widget.draft,
      groupInfoM: widget.groupInfoNotifier?.value,
      userInfoM: widget.userInfoNotifier?.value,
      hintText: widget.hintText,
      repliedMsgM: repliedMsgM,
      repliedUser: repliedUserInfoM,
      repliedImageFile: repliedImageFile,
      onCancelReply: _onCancelReply,
      sendText: (text, type) {
        int? targetMid;
        if (type == SendType.reply) {
          targetMid = repliedMsgM?.mid;
          return _send(text, type, uuid(), targetMid);
        } else if (type == SendType.edit) {
          targetMid = _editingMsgM?.mid;
          return _send(text, type, _editingMsgM!.localMid, targetMid);
        } else {
          return _send(text, type, uuid());
        }
      },
      onSendFile: (path, type) {
        return _send(path, type, uuid());
      },
      sendBtnType: _sendTypeNotifier,
    );
  }

  Future<void> _onMsg(ChatMsgM chatMsgM, String localMid, dynamic data,
      {bool frontInsert = true}) async {
    // Check if the message is an auto-deletion one and is out-of-date
    // print(
    //     "content: ${chatMsgM.msgNormal?.content}  expires?:${chatMsgM.expires}");
    if (chatMsgM.expires) {
      await ChatMsgDao().deleteMsgByLocalMid(chatMsgM);
      if (chatMsgM.isGroupMsg) {
        final curMaxMid = await ChatMsgDao().getChannelMaxMid(chatMsgM.gid);
        if (curMaxMid > -1) {
          final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

          if (msg != null) {
            App.app.chatService.fireSnippet(msg);
          }
        }
      } else {
        final curMaxMid = await ChatMsgDao().getDmMaxMid(chatMsgM.dmUid);
        if (curMaxMid > -1) {
          final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

          if (msg != null) {
            App.app.chatService.fireSnippet(msg);
          }
        }
      }
      return;
    }

    if (widget._isGroup) {
      if (chatMsgM.gid != widget.groupInfoNotifier?.value.gid) {
        return;
      }

      // Use msgCount to determine whether to show ChannelStart widget.
      // widget.msgCount = await ChatMsgDao().getChatMsgCount(gid: chatMsgM.gid);

      // Update read index and unread count
      if (chatMsgM.mid > _initReadIndex) {
        App.app.chatService.addGroupReadIndex(
            chatMsgM.mid, widget.groupInfoNotifier!.value.gid);
        taskQueue.add(() => GroupInfoDao()
                .updateProperties(chatMsgM.gid, readIndex: chatMsgM.mid)
                .then((value) {
              if (globals.unreadCountSum.value > 0) {
                globals.unreadCountSum.value -= 1;
              }
            }));
      }
    } else {
      if (chatMsgM.dmUid != widget.userInfoNotifier?.value.uid) {
        return;
      }

      // Use msgCount to determine whether to show ChannelStart widget.
      // widget.msgCount = await ChatMsgDao().getChatMsgCount(uid: chatMsgM.dmUid);

      // Update read index and unread count.
      if (widget.userInfoNotifier?.value.properties.readIndex != null &&
          chatMsgM.mid > widget.userInfoNotifier!.value.properties.readIndex) {
        App.app.chatService
            .addUserReadIndex(chatMsgM.mid, widget.userInfoNotifier!.value.uid);

        taskQueue.add(() => UserInfoDao()
                .updateProperties(widget.userInfoNotifier!.value.uid,
                    readIndex: chatMsgM.mid)
                .then((value) {
              if (globals.unreadCountSum.value > 0) {
                globals.unreadCountSum.value -= 1;
              }
            }));
      }
    }

    if (!_userInfoMMap.containsKey(chatMsgM.fromUid)) {
      final userInfoM = await UserInfoDao().getUserByUid(chatMsgM.fromUid);
      if (userInfoM != null) {
        _userInfoMMap.addAll({chatMsgM.fromUid: userInfoM});
      }
    }

    switch (chatMsgM.type) {
      case MsgDetailType.normal:
        switch (chatMsgM.detailType) {
          case MsgContentType.text:
          case MsgContentType.markdown:
            if (!_localMidSet.contains(localMid)) {
              _localMidSet.add(localMid);
              if (frontInsert) {
                _uiMsgList.insert(0, UiMsg(chatMsgM: chatMsgM));
              } else {
                _uiMsgList.add(UiMsg(chatMsgM: chatMsgM));
              }
            } else {
              final index = _uiMsgList.indexWhere(
                  (element) => element.chatMsgM.localMid == chatMsgM.localMid);
              if (index > -1) {
                _uiMsgList[index].chatMsgM = chatMsgM;
              }
            }
            break;
          case MsgContentType.file:
            final fileType = chatMsgM.fileContentType;

            if (fileType.isEmpty) {
              App.logger.warning(chatMsgM.values);
            }

            File? fileFile = data as File?;

            if (!_localMidSet.contains(localMid)) {
              _localMidSet.add(localMid);
              if (frontInsert) {
                _uiMsgList.insert(0, UiMsg(chatMsgM: chatMsgM, file: fileFile));
              } else {
                _uiMsgList.add(UiMsg(chatMsgM: chatMsgM, file: fileFile));
              }
            } else {
              final index = _uiMsgList.indexWhere(
                  (element) => element.chatMsgM.localMid == chatMsgM.localMid);
              if (index > -1) {
                _uiMsgList[index].chatMsgM = chatMsgM;
                _uiMsgList[index].file = fileFile;
              }
            }

            break;
          case MsgContentType.archive:
            final archive = data as Archive?;

            if (!_localMidSet.contains(localMid)) {
              _localMidSet.add(localMid);
              if (frontInsert) {
                _uiMsgList.insert(
                    0, UiMsg(chatMsgM: chatMsgM, archive: archive));
              } else {
                _uiMsgList.add(UiMsg(chatMsgM: chatMsgM, archive: archive));
              }
            } else {
              final index = _uiMsgList.indexWhere(
                  (element) => element.chatMsgM.localMid == chatMsgM.localMid);
              if (index > -1) {
                _uiMsgList[index].chatMsgM = chatMsgM;
                _uiMsgList[index].archive = archive;
              }
            }
            break;
          default:
            if (!_localMidSet.contains(localMid)) {
              _localMidSet.add(localMid);
              if (frontInsert) {
                _uiMsgList.insert(0, UiMsg(chatMsgM: chatMsgM));
              } else {
                _uiMsgList.add(UiMsg(chatMsgM: chatMsgM));
              }
            } else {
              final index = _uiMsgList.indexWhere(
                  (element) => element.chatMsgM.localMid == chatMsgM.localMid);
              if (index > -1) {
                _uiMsgList[index].chatMsgM = chatMsgM;
              }
            }
            break;
        }
        break;
      case MsgDetailType.reply:
        int? targetMid = json.decode(chatMsgM.detail)["mid"];

        if (targetMid != null) {
          final repliedMsg = await ChatMsgDao().getMsgByMid(targetMid);
          if (repliedMsg != null) {
            final int? targetUid = repliedMsg.fromUid;
            if (targetUid != null) {
              UserInfoM repliedUserInfoM =
                  await UserInfoDao().getUserByUid(targetUid) ??
                      UserInfoM.deleted();

              switch (repliedMsg.detailContentType) {
                case typeFile:
                  if (repliedMsg.isImageMsg) {
                    final thumbFile = await FileHandler.singleton
                        .getLocalImageThumb(repliedMsg);

                    if (thumbFile != null) {
                      if (!_localMidSet.contains(chatMsgM.localMid)) {
                        _localMidSet.add(chatMsgM.localMid);
                        _uiMsgList.add(UiMsg(
                            chatMsgM: chatMsgM,
                            repliedMsgM: repliedMsg,
                            repliedUserInfoM: repliedUserInfoM,
                            repliedThumbFile: thumbFile));
                      } else {
                        final index = _uiMsgList.indexWhere((element) =>
                            element.chatMsgM.localMid == chatMsgM.localMid);
                        if (index > -1) {
                          _uiMsgList[index].chatMsgM = chatMsgM;
                        }
                      }
                    }
                  } else {
                    if (!_localMidSet.contains(chatMsgM.localMid)) {
                      _localMidSet.add(chatMsgM.localMid);
                      _uiMsgList.add(UiMsg(
                          chatMsgM: chatMsgM,
                          repliedMsgM: repliedMsg,
                          repliedUserInfoM: repliedUserInfoM));
                    } else {
                      final index = _uiMsgList.indexWhere((element) =>
                          element.chatMsgM.localMid == chatMsgM.localMid);
                      if (index > -1) {
                        _uiMsgList[index].chatMsgM = chatMsgM;
                      }
                    }
                  }

                  break;
                default:
                  if (!_localMidSet.contains(chatMsgM.localMid)) {
                    _localMidSet.add(chatMsgM.localMid);
                    _uiMsgList.add(UiMsg(
                        chatMsgM: chatMsgM,
                        repliedMsgM: repliedMsg,
                        repliedUserInfoM: repliedUserInfoM));
                  } else {
                    final index = _uiMsgList.indexWhere((element) =>
                        element.chatMsgM.localMid == chatMsgM.localMid);
                    if (index > -1) {
                      _uiMsgList[index].chatMsgM = chatMsgM;
                    }
                  }
              }
            } else {
              App.logger
                  .severe("Replied uid not found. mid: ${repliedMsg.mid}");
            }
          } else {
            App.logger.warning("Replied Msg not found. mid: $targetMid");
            final uiMsg = UiMsg(chatMsgM: chatMsgM);
            _uiMsgList.add(uiMsg);
          }
        } else {
          App.logger
              .severe("Target Mid not found. reply msg mid: ${chatMsgM.mid}");
        }
        break;

      default:
        break;
    }

    _uiMsgList.sort((a, b) => b.chatMsgM.mid.compareTo(a.chatMsgM.mid));

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onReaction(ReactionTypes type, int mid,
      [ChatMsgM? chatMsgM]) async {
    switch (type) {
      case ReactionTypes.edit:
        if (chatMsgM != null) {
          final index = _uiMsgList.indexWhere(
              (element) => element.chatMsgM.localMid == chatMsgM.localMid);
          if (index > -1) {
            _uiMsgList[index].chatMsgM = chatMsgM;
          }
        }
        break;
      case ReactionTypes.like:
        if (chatMsgM != null) {
          final index = _uiMsgList.indexWhere(
              (element) => element.chatMsgM.localMid == chatMsgM.localMid);
          if (index > -1) {
            _uiMsgList[index].chatMsgM = chatMsgM;
          }
        }

        break;
      case ReactionTypes.delete:
        final midIndex =
            _uiMsgList.indexWhere((element) => element.chatMsgM.mid == mid);

        if (midIndex > -1) {
          _uiMsgList.removeAt(midIndex);
        }

        for (var i = 0; i < _uiMsgList.length; i++) {
          if (_uiMsgList[i].repliedMsgM?.mid == mid) {
            _uiMsgList[i]
              ..repliedMsgM = null
              ..repliedThumbFile = null
              ..repliedUserInfoM = null;
          }
        }

        break;
      default:
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onUser(UserInfoM m, EventActions action) async {
    if (_userInfoMMap.containsKey(m.uid)) {
      _userInfoMMap[m.uid] = m;
    }

    if (widget.userInfoNotifier?.value.uid == m.uid) {
      switch (action) {
        case EventActions.update:
          widget.userInfoNotifier!.value = m;
          break;
        default:
      }
    }
    return;
  }

  Future<void> _onGroup(GroupInfoM m, EventActions action) async {
    if (widget.groupInfoNotifier?.value.gid == m.gid) {
      switch (action) {
        case EventActions.update:
          widget.groupInfoNotifier!.value = m;

          if (mounted) {
            setState(() {});
          }

          break;
        default:
      }
    }
  }

  void _onTapReply(ChatMsgM m, File? imageFile) async {
    _sendTypeNotifier.value = SendType.reply;
    final u = await UserInfoDao().getUserByUid(m.fromUid);
    if (u != null) {
      if (mounted) {
        setState(() {
          repliedUserInfoM = u;
          repliedMsgM = m;
          repliedImageFile = imageFile;
        });
      }
      widget._focusNode.requestFocus();
      Navigator.of(context).pop();
    } else {
      App.logger.severe("Can't find user.");
    }
  }

  void _onCancelReply() {
    _sendTypeNotifier.value = SendType.normal;
    if (mounted) {
      setState(() {
        repliedMsgM = null;
        repliedUserInfoM = null;
        repliedImageFile = null;
      });
    }
  }

  void _onTapEdit(ChatMsgM chatMsgM) {
    Navigator.of(context).pop();
    if (chatMsgM.detailContentType == typeFile) {
      return;
    }

    final controller = widget.mentionsKey.currentState?.controller;
    if (controller == null) {
      return;
    }
    final dynamic old;
    if (chatMsgM.msgNormal != null) {
      old = chatMsgM.msgNormal;
    } else {
      old = chatMsgM.msgReply;
    }

    widget.mentionsKey.currentState?.controller?.text = old!.content;

    // change send button to edit.
    _sendTypeNotifier.value = SendType.edit;
    _editingMsgM = chatMsgM;
  }

  /// Copy texts to clipboard.
  ///
  /// Only executes for text and markdown messages.
  void _onTapCopy(ChatMsgM chatMsgM) async {
    assert(chatMsgM.detailType == MsgContentType.text ||
        chatMsgM.detailType == MsgContentType.markdown);

    String content =
        chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? "";
    if (chatMsgM.detailType == MsgContentType.text) {
      content = await SharedFuncs.parseMention(content);
    }

    if (content.isNotEmpty) Clipboard.setData(ClipboardData(text: content));
    Navigator.of(context).pop();
  }

  void _onTapPin(ChatMsgM chatMsgM, bool toPin) async {
    Navigator.of(context).pop();
    final gid = chatMsgM.gid;
    final mid = chatMsgM.mid;

    try {
      final groupApi = GroupApi();
      await groupApi.pin(gid, mid, toPin);
    } catch (e) {
      App.logger.severe(e);
    }
  }

  void _onTapSave(ChatMsgM chatMsgM) async {
    assert(chatMsgM.detailType != MsgContentType.archive);

    List<int> midList = [];
    midList.add(chatMsgM.mid);
    try {
      final savedApi = SavedApi();
      await savedApi.createSaved(midList);
      // Navigator.of(context).pop();
    } catch (e) {
      App.logger.severe(e);
    }

    Navigator.of(context).pop();
  }

  void _onTapTileForward(ChatMsgM chatMsgM) async {
    Navigator.of(context).pop();

    if (chatMsgM.detailType == MsgContentType.archive) {
      String? archiveId = chatMsgM.msgNormal?.content;

      if (archiveId == null) return;

      await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8), topRight: Radius.circular(8))),
          builder: (context) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: ChatSelectionSheet(
                title: AppLocalizations.of(context)!.forwardTo,
                onSubmit: (uidNotifier, gidNotifier, buttonStatus) async {
                  buttonStatus.value = ButtonStatus.inProgress;

                  final res = await App.app.chatService.sendArchiveForward(
                      archiveId, uidNotifier.value, gidNotifier.value);
                  if (res) {
                    buttonStatus.value = ButtonStatus.success;
                  } else {
                    buttonStatus.value = ButtonStatus.error;
                  }
                  Future.delayed(Duration(seconds: 2)).then((value) {
                    buttonStatus.value = ButtonStatus.normal;
                  });
                },
              ),
            );
          });
      return;
    }

    selectedMsgMList.value = List.from(selectedMsgMList.value)..add(chatMsgM);
    selectedMsgMList.notifyListeners();
    _forward();
  }

  void _onTapSelect(ChatMsgM chatMsgM) {
    Navigator.of(context).pop();
    selectedMsgMList.value = List.from(selectedMsgMList.value)..add(chatMsgM);

    selectedMsgCantMultipleArchive.value = selectedMsgMList.value.any(
      (element) {
        return element.detailType == MsgContentType.archive ||
            element.status != MsgSendStatus.success.name;
      },
    );
    if (mounted) {
      setState(() {
        isSelecting.value = true;
      });
    }
  }

  void _forward() async {
    final midList = selectedMsgMList.value.map((e) => e.mid).toList();
    if (midList.isEmpty) {
      return;
    }

    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8), topRight: Radius.circular(8))),
        builder: (context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: ChatSelectionSheet(
              title: AppLocalizations.of(context)!.forwardTo,
              onSubmit: (uidNotifier, gidNotifier, buttonStatus) async {
                buttonStatus.value = ButtonStatus.inProgress;
                final res = await App.app.chatService
                    .sendForward(midList, uidNotifier.value, gidNotifier.value);
                if (res) {
                  buttonStatus.value = ButtonStatus.success;
                } else {
                  buttonStatus.value = ButtonStatus.error;
                }
                Future.delayed(Duration(seconds: 2)).then((value) {
                  buttonStatus.value = ButtonStatus.normal;
                });
              },
            ),
          );
        });
    if (mounted) {
      setState(() {
        selectedMsgMList.value.clear();
        isSelecting.value = false;
      });
    }
  }

  void _createSavedItem() async {
    final midList = selectedMsgMList.value.map((e) => e.mid).toList();
    if (midList.isEmpty) {
      return;
    }
    try {
      for (var mid in midList) {
        final savedApi = SavedApi();
        savedApi.createSaved([mid]);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    if (mounted) {
      setState(() {
        selectedMsgMList.value.clear();
        isSelecting.value = false;
      });
    }
  }

  void _batchDelete() async {
    if (selectedMsgMList.value.isEmpty) {
      return;
    }

    for (var chatMsgM in selectedMsgMList.value) {
      await _onDeleteNew(chatMsgM);
    }
    if (mounted) {
      setState(() {
        selectedMsgMList.value.clear();
        isSelecting.value = false;
      });
    }

    if (_uiMsgList.length < 15) {
      _loadHistory();
    }
  }

  Future<bool> _sendReaction(ChatMsgM old, String reaction) async {
    if (mounted) {
      setState(() {
        final index = _uiMsgList
            .indexWhere((element) => element.chatMsgM.localMid == old.localMid);
        if (index > -1) {
          _uiMsgList[index].chatMsgM.status = MsgSendStatus.sending.name;
        }
      });
    }

    try {
      final messageApi = MessageApi();
      await messageApi.react(old.mid, reaction);
    } catch (e) {
      App.logger.severe(e);
      if (mounted) {
        setState(() {
          final index = _uiMsgList.indexWhere(
              (element) => element.chatMsgM.localMid == old.localMid);
          if (index > -1) {
            _uiMsgList[index].chatMsgM.status = MsgSendStatus.fail.name;
          }
        });
      }
      return false;
    }
    if (mounted) {
      setState(() {
        final index = _uiMsgList
            .indexWhere((element) => element.chatMsgM.localMid == old.localMid);
        if (index > -1) {
          _uiMsgList[index].chatMsgM.status = MsgSendStatus.success.name;
        }
      });
    }
    return true;
  }

  Future<bool> _onDeleteNew(ChatMsgM old) async {
    try {
      await MessageApi().delete(old.mid).then((response) async {
        if (response.statusCode == 200) {
          // successfully deleted
          FileHandler.singleton.deleteWithChatMsgM(old);

          final index = _uiMsgList.indexWhere(
              (element) => element.chatMsgM.localMid == old.localMid);
          ChatMsgDao().deleteMsgByLocalMid(old).then((successful) async {
            if (successful) {
              if (mounted) {
                setState(() {
                  _uiMsgList.remove(_uiMsgList[index]);
                });
              }

              if (old.isGroupMsg) {
                final curMaxMid = await ChatMsgDao().getChannelMaxMid(old.gid);
                if (curMaxMid > -1) {
                  final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

                  if (msg != null) {
                    App.app.chatService.fireSnippet(msg);
                  }
                }
              } else {
                final curMaxMid = await ChatMsgDao().getDmMaxMid(old.dmUid);
                if (curMaxMid > -1) {
                  final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

                  if (msg != null) {
                    App.app.chatService.fireSnippet(msg);
                  }
                }
              }

              return true;
            }
          });
        } else {
          App.logger.severe("Message deletion failed. Message: $old");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.messageDeletionFailed)));
          }
          return false;
        }
      });
    } catch (e) {
      App.logger.severe("Message deletion failed. Message: $old, Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.messageDeletionFailed)));
      }
    }

    return false;
  }

  Future<bool> _onDelete(ChatMsgM old) async {
    final index = _uiMsgList
        .indexWhere((element) => element.chatMsgM.localMid == old.localMid);
    try {
      await ChatMsgDao().deleteMsgByLocalMid(old);
      if (mounted) {
        setState(() {
          _uiMsgList.remove(_uiMsgList[index]);
        });
      }

      if (old.isGroupMsg) {
        final curMaxMid = await ChatMsgDao().getChannelMaxMid(old.gid);
        if (curMaxMid > -1) {
          final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

          if (msg != null) {
            App.app.chatService.fireSnippet(msg);
          }
        }
      } else {
        final curMaxMid = await ChatMsgDao().getDmMaxMid(old.dmUid);
        if (curMaxMid > -1) {
          final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

          if (msg != null) {
            App.app.chatService.fireSnippet(msg);
          }
        }
      }

      await FileHandler.singleton.deleteWithChatMsgM(old);

      final messageApi = MessageApi();

      await messageApi.delete(old.mid);
    } catch (e) {
      App.logger.severe(e);
      final index = _uiMsgList
          .indexWhere((element) => element.chatMsgM.localMid == old.localMid);
      if (index > -1) {
        if (mounted) {
          setState(() {
            _uiMsgList[index].chatMsgM.status = MsgSendStatus.fail.name;
          });
        }
      }
      return false;
    }
    return true;
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildMsgList() {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        scrollDirection: scrollDirection,
        controller: _scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        reverse: true,
        shrinkWrap: true,
        // Additional 1 tile for retriving history messages
        itemCount: _uiMsgList.length + 1,
        itemBuilder: (context, index) {
          if (index == _uiMsgList.length) {
            if (_isLoadingHistory) {
              return SizedBox(
                  height: 20,
                  width: 20,
                  child: Center(child: CupertinoActivityIndicator()));
            } else {
              return SizedBox(height: 20, width: 20);
            }
          } else {
            UiMsg uiMsg = _uiMsgList[index];

            final userInfoM =
                _userInfoMMap[uiMsg.chatMsgM.fromUid] ?? UserInfoM.deleted();
            final isSelf = userInfoM.uid == App.app.userDb!.uid;
            final isOwner = widget.groupInfoNotifier?.value.groupInfo.owner ==
                App.app.userDb?.uid;
            final isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;

            final pinIndex = widget
                    .groupInfoNotifier?.value.groupInfo.pinnedMessages
                    .indexWhere((e) => e.mid == uiMsg.chatMsgM.mid) ??
                -1;
            final pinnedBy = pinIndex > -1
                ? widget.groupInfoNotifier?.value.groupInfo
                        .pinnedMessages[pinIndex].createdBy ??
                    0
                : 0;

            Widget msgTile = Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              color: _getMsgTileBgColor(
                  isPinned: pinnedBy != 0,
                  isAutoDeletion: _isAutoDeletionMsg(uiMsg.chatMsgM)),
              child: Row(
                children: [
                  MessageTile(
                    key: Key(uiMsg.chatMsgM.localMid),
                    avatarSize: VoceAvatarSize.s42,
                    isFollowing: false,
                    chatMsgM: uiMsg.chatMsgM,
                    userInfoM: userInfoM,
                    isSelecting: isSelecting,
                    repliedMsgM: uiMsg.repliedMsgM,
                    repliedUserInfoM: uiMsg.repliedUserInfoM,
                    repliedImageFile: uiMsg.repliedThumbFile,
                    image: uiMsg.file,
                    enableAvatarMention: widget._isGroup,
                    mentionsKey: widget.mentionsKey,
                    archive: uiMsg.archive,
                    onSendReaction: _sendReaction,
                    selectNotifier: selectedMsgMList,
                    pinnedBy: pinnedBy,
                    onChanged: (selected) {
                      if (selected) {
                        selectedMsgMList.value =
                            List.from(selectedMsgMList.value)
                              ..add(uiMsg.chatMsgM);
                      } else {
                        selectedMsgMList.value =
                            List.from(selectedMsgMList.value)
                              ..removeWhere((element) =>
                                  element.localMid == uiMsg.chatMsgM.localMid);
                      }
                      selectedMsgCantMultipleArchive.value =
                          selectedMsgMList.value.any(
                        (element) {
                          return element.detailType == MsgContentType.archive ||
                              element.status != MsgSendStatus.success.name;
                        },
                      );
                    },
                  ),
                  Container(
                      width: 50,
                      alignment: Alignment.centerLeft,
                      child: _buildStatus(uiMsg, index))
                ],
              ),
            );

            return GestureDetector(
                onLongPress: () {
                  showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8))),
                      builder: (context) {
                        return MsgActionsSheet(
                          chatMsgM: uiMsg.chatMsgM,
                          onReaction: (reaction) {
                            _sendReaction(uiMsg.chatMsgM, reaction);
                          },
                          reactions: uiMsg.chatMsgM.reactions,
                          actions: [
                            if (uiMsg.chatMsgM.status ==
                                MsgSendStatus.success.name)
                              MsgActionTile(
                                  icon: AppIcons.reply,
                                  title: AppLocalizations.of(context)!.reply,
                                  onTap: () {
                                    _onTapReply(uiMsg.chatMsgM, uiMsg.file);
                                  }),
                            if (isSelf &&
                                uiMsg.chatMsgM.detailContentType ==
                                    'text/plain' &&
                                uiMsg.chatMsgM.status ==
                                    MsgSendStatus.success.name)
                              MsgActionTile(
                                  icon: AppIcons.edit,
                                  title: AppLocalizations.of(context)!.edit,
                                  onTap: () {
                                    _onTapEdit(uiMsg.chatMsgM);
                                  }),
                            if (uiMsg.chatMsgM.detailType ==
                                    MsgContentType.text ||
                                uiMsg.chatMsgM.detailType ==
                                    MsgContentType.markdown)
                              MsgActionTile(
                                  icon: Icons.copy,
                                  title: AppLocalizations.of(context)!.copy,
                                  onTap: () {
                                    _onTapCopy(uiMsg.chatMsgM);
                                  }),
                            if ((isAdmin || isOwner) &&
                                widget._isGroup &&
                                uiMsg.chatMsgM.status ==
                                    MsgSendStatus.success.name)
                              _buildPinAction(uiMsg.chatMsgM),
                            if (uiMsg.chatMsgM.detailType !=
                                    MsgContentType.archive &&
                                uiMsg.chatMsgM.status ==
                                    MsgSendStatus.success.name)
                              MsgActionTile(
                                  icon: AppIcons.bookmark,
                                  title: AppLocalizations.of(context)!.save,
                                  onTap: () {
                                    _onTapSave(uiMsg.chatMsgM);
                                  }),
                            if (uiMsg.chatMsgM.status ==
                                MsgSendStatus.success.name)
                              MsgActionTile(
                                  icon: AppIcons.forward,
                                  title: AppLocalizations.of(context)!.forward,
                                  onTap: () {
                                    _onTapTileForward(uiMsg.chatMsgM);
                                  }),
                            MsgActionTile(
                                icon: AppIcons.select,
                                title: AppLocalizations.of(context)!.select,
                                onTap: () {
                                  _onTapSelect(uiMsg.chatMsgM);
                                }),
                            if (isSelf || isAdmin || isOwner)
                              MsgActionTile(
                                  icon: AppIcons.delete,
                                  title: AppLocalizations.of(context)!.delete,
                                  color: Colors.red,
                                  onTap: () {
                                    _onDeleteNew(uiMsg.chatMsgM);
                                    Navigator.of(context).pop();
                                  }),
                          ],
                        );
                      });
                },
                child: msgTile);
          }
        },
      ),
    );
  }

  Color _getMsgTileBgColor(
      {required bool isPinned, required bool isAutoDeletion}) {
    if (isAutoDeletion) {
      return Color.fromRGBO(249, 241, 239, 1);
    } else if (isPinned) {
      return Color.fromRGBO(239, 252, 255, 1);
    } else {
      return Colors.white;
    }
  }

  bool _isAutoDeletionMsg(ChatMsgM chatMsgM) {
    final isMsgNormalAutoDeletion = chatMsgM.msgNormal?.expiresIn != null &&
        chatMsgM.msgNormal?.expiresIn != 0;

    return isMsgNormalAutoDeletion;
  }

  MsgActionTile _buildPinAction(ChatMsgM chatMsgM) {
    final pinnedMessages = widget
            .groupInfoNotifier?.value.groupInfo.pinnedMessages
            .map((e) => e.mid) ??
        [];
    bool pinned = pinnedMessages.contains(chatMsgM.mid);
    return MsgActionTile(
        icon: AppIcons.pin,
        title: pinned
            ? AppLocalizations.of(context)!.unpin
            : AppLocalizations.of(context)!.pin,
        onTap: () {
          _onTapPin(chatMsgM, !pinned);
        });
  }

  bool _isFollowing(int index) {
    if (index == _uiMsgList.length - 1) {
      return false;
    }
    if (index + 1 < _uiMsgList.length) {
      var old = _uiMsgList[index + 1].chatMsgM;
      var cur = _uiMsgList[index].chatMsgM;
      return (old.fromUid == cur.fromUid &&
          cur.createdAt - old.createdAt <= 300000);
    }
    return true;
  }

  Widget _buildStatus(UiMsg uiMsg, int index) {
    Widget icon;

    final localMid = uiMsg.chatMsgM.localMid;
    final msgStatus = SharedFuncs.getMsgSendStatus(uiMsg.chatMsgM.status);

    // [SendService.isWaitingOrExecuting] is not super accurate:
    // Sometimes the message finishes sending, but the task is still in queue
    // for a short while, causing the status in [uiMsg] shows success, but
    // [SendService.isWaitingOrExecuting] still returns true.
    // The priority of status determination is uiMsg.chatMsgM, then
    // SendTaskQueue.
    MsgSendStatus status;
    if (msgStatus == MsgSendStatus.success) {
      status = MsgSendStatus.success;
    } else {
      status = SendTaskQueue.singleton.isWaitingOrExecuting(localMid)
          ? MsgSendStatus.sending
          : msgStatus;
    }

    if (uiMsg.chatMsgM.detailContentType == typeFile) {
      if (status == MsgSendStatus.sending) {
        final task = SendTaskQueue.singleton.getTask(uiMsg.chatMsgM.localMid);
        if (task != null && task.progress != null) {
          return ValueListenableBuilder<double>(
            valueListenable: task.progress!,
            builder: (context, value, child) {
              if (value <= 0) {
                value = 0.01;
              }

              return SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    value: value, backgroundColor: AppColors.grey200),
              );
            },
          );
        }
      }
    }

    double radius = 10;
    icon = Center(child: CupertinoActivityIndicator(radius: radius));

    if (status == MsgSendStatus.success) {
      icon = SizedBox.shrink();
    } else if (status == MsgSendStatus.fail) {
      icon = GestureDetector(
          onTap: () async {
            await showAppAlert(
                context: context,
                title: AppLocalizations.of(context)!.chatPageResendWarning,
                content:
                    AppLocalizations.of(context)!.chatPageResendWarningContent,
                primaryAction: AppAlertDialogAction(
                    text: AppLocalizations.of(context)!.resend,
                    action: () {
                      final chatMsgM = uiMsg.chatMsgM;
                      final content = chatMsgM.msgNormal?.content ??
                          chatMsgM.msgReply?.content ??
                          "";

                      switch (SharedFuncs.getSendType(chatMsgM)) {
                        case SendType.normal:
                        case SendType.cancel:
                          _send(content, SharedFuncs.getSendType(chatMsgM),
                              localMid);

                          break;
                        case SendType.file:
                          if (chatMsgM.isImageMsg) {
                            _resendImage(chatMsgM);
                          } else {
                            _resendFile(chatMsgM);
                          }
                          break;
                        case SendType.edit:
                          int? targetMid = chatMsgM.mid;
                          _send(content, SendType.edit, chatMsgM.localMid,
                              targetMid);
                          break;

                        case SendType.reply:
                          int? targetMid = chatMsgM.msgReply?.mid;
                          _send(content, SendType.reply, chatMsgM.localMid,
                              targetMid);
                          break;
                        default:
                      }

                      Navigator.of(context).pop();
                    },
                    isDangerAction: true),
                actions: [
                  AppAlertDialogAction(
                      text: AppLocalizations.of(context)!.cancel,
                      action: () => Navigator.of(context).pop())
                ]);
          },
          child:
              Icon(Icons.error, size: radius * 2.5, color: AppColors.errorRed));
    }

    return icon;
  }

  void _resendImage(ChatMsgM chatMsgM) async {
    final imageNormal =
        await FileHandler.singleton.getLocalImageNormal(chatMsgM);
    if (imageNormal != null) {
      final path = imageNormal.path;
      _send(path, SendType.file, chatMsgM.localMid);
    } else {
      showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.chatPageCantFindImageWarning,
          content:
              AppLocalizations.of(context)!.chatPageCantFindImageWarningContent,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.ok,
                action: () => Navigator.of(context).pop())
          ]);
    }
  }

  void _resendFile(ChatMsgM chatMsgM) async {
    final file = await FileHandler.singleton.getLocalFile(chatMsgM);
    if (file != null) {
      final path = file.path;
      _send(path, SendType.file, chatMsgM.localMid);
    } else {
      showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.chatPageCantFindFileWarning,
          content:
              AppLocalizations.of(context)!.chatPageCantFindFileWarningContent,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.ok,
                action: () => Navigator.of(context).pop())
          ]);
    }
  }

  List<int> getHeaderBytes(String path) {
    List<int> fileBytes = File(path).readAsBytesSync().toList();

    List<int> header = [];

    for (var element in fileBytes) {
      if (element == 0) return [];
      header.add(element);
    }
    return header;
  }

  Future<void> _loadHistory() async {
    if (_isLoadingHistory) {
      return;
    }
    if (mounted) {
      setState(() {
        _isLoadingHistory = true;
      });
    }

    _pageMeta.pageNumber = (_uiMsgList.length / _pageMeta.pageSize).floor();

    PageData<ChatMsgM> page;
    if (widget._isGroup) {
      page = await ChatMsgDao().paginateLastByGid(
          _pageMeta..pageNumber += 1, '', widget.groupInfoNotifier!.value.gid);
    } else {
      page = await ChatMsgDao().paginateLastByDmUid(
          _pageMeta..pageNumber += 1, '', widget.userInfoNotifier!.value.uid);
    }

    for (ChatMsgM m in page.records.reversed) {
      switch (m.type) {
        case MsgDetailType.normal:
          switch (m.detailType) {
            case MsgContentType.text:
            case MsgContentType.markdown:
            case MsgContentType.file:
              if (m.isImageMsg) {
                File? imageFile;
                if (m.isGifImageMsg) {
                  imageFile = await FileHandler.singleton.getImageNormal(m);
                } else {
                  imageFile = await FileHandler.singleton.getImageThumb(m);
                }

                if (imageFile != null) {
                  await _onMsg(m, m.localMid, imageFile, frontInsert: false);
                } else {
                  await _onMsg(m, m.localMid, null, frontInsert: false);
                }
              } else {
                await _onMsg(m, m.localMid, null, frontInsert: false);
                break;
              }
              break;
            case MsgContentType.archive:
              final archiveId = m.msgNormal!.content;
              final archiveM = await ArchiveDao().getArchive(archiveId);

              if (archiveM != null) {
                await _onMsg(m, m.localMid, archiveM.archive,
                    frontInsert: false);
              } else {
                await _onMsg(m, m.localMid, null, frontInsert: false);
                App.logger.severe("archive missing. Id: $archiveId");
              }

              break;

            default:
          }
          break;
        case MsgDetailType.reply:
          await _onMsg(m, m.localMid, null, frontInsert: false);
          break;
        default:
      }
    }

    // Check if all messages in this page are valid.
    // If some messages are invalid, which means the first page might be empty.
    // We need a full first page, so do recursion on [_loadHistory] function.
    {
      List<ChatMsgM> valids = page.records;
      valids.retainWhere((element) => element.expires);
      final validsCount = valids.length;

      if (_uiMsgList.length < validsCount) {
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
        }
        _loadHistory();
      }
    }

    if (page.records.length < _pageMeta.pageSize) {
      // _loadServerHistory();
    }

    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadServerHistory() async {
    if (!widget._isGroup) return;

    final gid = widget.groupInfoNotifier?.value.gid;
    if (gid == null) return;

    final minMid = await ChatMsgDao().getMinMidInChannel(gid);

    final groupApi = GroupApi();
    final res = await groupApi.getHistory(gid, minMid);

    if (res.statusCode != 200 || res.data == null) return;

    for (var each in res.data) {
      App.app.chatService.handleHistoryChatMsg(each);
    }
  }

  Future<bool> _send(String msg, SendType type, String localMid,
      [int? targetMid]) async {
    _scrollToBottom();

    switch (type) {
      case SendType.normal:
        SendService.singleton.sendMessage(localMid, msg, type,
            gid: widget.groupInfoNotifier?.value.gid,
            uid: widget.userInfoNotifier?.value.uid);
        break;
      case SendType.edit:
        SendService.singleton.sendMessage(localMid, msg, type,
            gid: widget.groupInfoNotifier?.value.gid,
            uid: widget.userInfoNotifier?.value.uid,
            targetMid: targetMid);

        _sendTypeNotifier.value = SendType.normal;
        break;
      case SendType.reply:
        SendService.singleton.sendMessage(localMid, msg, type,
            gid: widget.groupInfoNotifier?.value.gid,
            uid: widget.userInfoNotifier?.value.uid,
            targetMid: targetMid);
        _sendTypeNotifier.value = SendType.normal;
        break;
      case SendType.file:
        // msg here is path.
        SendService.singleton.sendMessage(localMid, msg, type,
            gid: widget.groupInfoNotifier?.value.gid,
            uid: widget.userInfoNotifier?.value.uid);
        break;
      case SendType.cancel:
        _sendTypeNotifier.value = SendType.normal;
        break;
      default:
    }
    if (mounted) {
      setState(() {
        repliedMsgM = null;
        repliedUserInfoM = null;
        repliedImageFile = null;
      });
    }
    return true;
  }
}
