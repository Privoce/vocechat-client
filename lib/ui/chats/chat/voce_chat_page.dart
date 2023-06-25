// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/lib/message_api.dart';
import 'package:vocechat_client/api/lib/saved_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/contacts.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/globals.dart' as globals;
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/models/ui_models/chat_page_controller.dart';
import 'package:vocechat_client/models/ui_models/msg_tile_data.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/file_handler/audio_file_handler.dart';
import 'package:vocechat_client/services/voce_audio_service.dart';
import 'package:vocechat_client/services/voce_send_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/chats/chat/chat_bar.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/chat_textfield.dart';
import 'package:vocechat_client/ui/chats/chat/msg_actions/msg_action_sheet.dart';
import 'package:vocechat_client/ui/chats/chat/msg_actions/msg_action_tile.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/voce_msg_tile.dart';
import 'package:vocechat_client/ui/widgets/app_busy_dialog.dart';
import 'package:vocechat_client/ui/widgets/channel_start.dart';
import 'package:vocechat_client/ui/widgets/chat_selection_sheet.dart';
import 'package:vocechat_client/ui/widgets/voce_context_menu.dart';

// ignore: must_be_immutable
class VoceChatPage extends StatefulWidget {
  static const route = "chats/chat";

  /// The total number of messages in the channel chat.
  /// Only available for channels. Used to show ChannelStart widget.
  // int msgCount;

  ValueNotifier<GroupInfoM>? groupInfoNotifier;
  ValueNotifier<UserInfoM>? userInfoNotifier;
  GlobalKey<AppMentionsState> mentionsKey;

  ChatPageController controller;

  final FocusNode _focusNode = FocusNode();

  VoceChatPage.user({
    Key? key,
    required this.mentionsKey,
    required this.controller,
  })  : groupInfoNotifier = null,
        userInfoNotifier = controller.userInfoMNotifier,
        super(key: key);

  VoceChatPage.channel({
    Key? key,
    required this.mentionsKey,
    required this.controller,
  })  : userInfoNotifier = null,
        groupInfoNotifier = controller.groupInfoMNotifier,
        super(key: key);

  bool get isChannel => controller.isChannel;
  bool get isUser => controller.isUser;

  @override
  State<VoceChatPage> createState() => _VoceChatPageState();
}

class _VoceChatPageState extends State<VoceChatPage>
    with SingleTickerProviderStateMixin {
  // actions
  final ValueNotifier<bool> selectEnabled = ValueNotifier(false);

  /// The map of selected [MsgTileData]s.
  ///
  /// The key is the [localMid].
  final Map<String, ValueNotifier<ChatMsgM>> selectedMsgMap = {};

  /// Indicated whether the selected messages contain at least one
  /// message that is an archive/failed/audio message.
  final ValueNotifier<bool> selectedMsgCantMultipleArchive =
      ValueNotifier(false);

  /// Indiated whether there is a busy task.
  ///
  /// Usually related to contacts.
  final ValueNotifier<bool> _isBusy = ValueNotifier(false);

  /// Save and notify listeners of the reactions that need to be sent to
  /// the text field.
  final ValueNotifier<ChatFieldReactionData> _reactionDataNotifier =
      ValueNotifier(ChatFieldReactionData(reactionType: ReactionType.normal));

  final ValueNotifier<bool> enableContact = ValueNotifier(false);

  final ScrollController _scrollController = ScrollController();

  /// The animation controller for the message tile.
  late final AnimationController _aniController;

  void showBusyDialog() {
    _isBusy.value = true;
  }

  void dismissBusyDialog() {
    _isBusy.value = false;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });

    widget.controller.addScrollToBottomListener(_scrollToBottom);

    // Create the animation controller and set its duration
    _aniController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    enableContact.value =
        App.app.chatServerM.properties.commonInfo?.contactVerificationEnable ==
            true;
    App.app.chatService.subscribeChatServer((chatServerM) async {
      enableContact.value =
          chatServerM.properties.commonInfo?.contactVerificationEnable == true;
    });
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    VoceAudioService().clear();
    widget.controller.removeScrollToBottomListener(_scrollToBottom);

    _aniController.dispose();

    App.app.chatService.unsubscribeChatServer((chatServerM) async {
      enableContact.value =
          chatServerM.properties.commonInfo?.contactVerificationEnable == true;
    });

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
            child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                    child: Column(
                  children: [
                    _buildContactStatusFloating(),
                    _buildVoceMsgList(),
                  ],
                )),
                ValueListenableBuilder<bool>(
                  valueListenable: selectEnabled,
                  builder: (context, isSelecting, child) {
                    if (isSelecting) {
                      return _buildSelectionBottomBar();
                    } else {
                      if (widget.userInfoNotifier != null) {
                        return _buildUserTextField();
                      } else {
                        return _buildTextField();
                      }
                    }
                  },
                )
              ],
            ),
            BusyDialog(busy: _isBusy)
          ],
        )),
      ),
    );
  }

  Widget _buildContactStatusFloating() {
    return ValueListenableBuilder<bool>(
        valueListenable: enableContact,
        builder: (context, enableContact, _) {
          if (widget.userInfoNotifier == null ||
              SharedFuncs.isSelf(widget.userInfoNotifier!.value.uid) ||
              !enableContact) {
            return SizedBox.shrink();
          }
          return ValueListenableBuilder<UserInfoM>(
            valueListenable: widget.userInfoNotifier!,
            builder: (context, userInfoM, child) {
              Widget widget;
              if (userInfoM.contactStatus == ContactStatus.blocked) {
                widget = Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 4),
                      child: Text(AppLocalizations.of(context)!.userBlocked,
                          style: AppTextStyles.labelMedium),
                    ),
                    CupertinoButton(
                        padding: const EdgeInsets.all(4.0),
                        onPressed: () => _unblockContact(userInfoM.uid),
                        child: _buildContactStatusActionBtn(Icons.block_flipped,
                            AppLocalizations.of(context)!.unblock, context))
                  ],
                );
              } else if (userInfoM.contactStatus == ContactStatus.none) {
                widget = Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 4),
                      child: Text(AppLocalizations.of(context)!.userNotContact,
                          style: AppTextStyles.labelMedium),
                    ),
                    Wrap(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      alignment: WrapAlignment.center,
                      children: [
                        CupertinoButton(
                            padding: const EdgeInsets.all(4.0),
                            onPressed: () => _addContact(userInfoM.uid),
                            child: _buildContactStatusActionBtn(
                                AppIcons.member_add,
                                AppLocalizations.of(context)!.addContact,
                                context)),
                        CupertinoButton(
                            padding: const EdgeInsets.all(4.0),
                            onPressed: () => _blockContact(userInfoM.uid),
                            child: _buildContactStatusActionBtn(
                                Icons.block_flipped,
                                AppLocalizations.of(context)!.block,
                                context))
                      ],
                    )
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
              return Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  width: double.maxFinite,
                  color: Colors.grey[200],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Center(child: widget));
            },
          );
        });
  }

  Container _buildContactStatusActionBtn(
      IconData icon, String text, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _unblockContact(int uid) async {
    showBusyDialog();

    await UserApi()
        .updateContactStatus(uid, ContactUpdateAction.unblock)
        .then((res) async {
      if (res.statusCode == 200) {
        await ContactDao()
            .updateContact(uid, ContactStatus.none)
            .then((updatedContactM) async {
          dismissBusyDialog();
        });
      } else {
        dismissBusyDialog();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.networkError)));
      }
    }).onError((error, stackTrace) {
      App.logger.severe(error);
      dismissBusyDialog();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.networkError)));
    });
  }

  Future<void> _blockContact(int uid) async {
    // Remove contact from contact list.
    // All messages will be kept.
    showBusyDialog();

    await UserApi()
        .updateContactStatus(uid, ContactUpdateAction.block)
        .then((res) async {
      if (res.statusCode == 200) {
        await ContactDao()
            .updateContact(uid, ContactStatus.blocked)
            .then((updatedContactM) async {
          dismissBusyDialog();
        });
      } else {
        dismissBusyDialog();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.networkError)));
      }
    }).onError((error, stackTrace) {
      App.logger.severe(error);
      dismissBusyDialog();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.networkError)));
    });
  }

  Future<void> _addContact(int uid) async {
    showBusyDialog();

    await UserApi()
        .updateContactStatus(uid, ContactUpdateAction.add)
        .then((res) async {
      if (res.statusCode == 200) {
        await ContactDao()
            .updateContact(uid, ContactStatus.added)
            .then((updatedContactM) async {
          dismissBusyDialog();
        });
      } else {
        dismissBusyDialog();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.networkError)));
      }
    }).onError((error, stackTrace) {
      App.logger.severe(error);
      dismissBusyDialog();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.networkError)));
    });
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
                          key: const ValueKey<int>(0),
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
                          key: const ValueKey<int>(1),
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
                    selectEnabled.value = false;
                    selectedMsgMap.clear();
                    widget.controller.clearMsgsSelection();
                    selectedMsgCantMultipleArchive.value = false;
                  },
                  child: Icon(AppIcons.close_circle,
                      size: 16, color: AppColors.grey600)),
            )
          ],
        ));
  }

  Widget _buildBlockedBottomBar() {
    return SizedBox(
        height: 56,
        width: double.maxFinite,
        child: Text(AppLocalizations.of(context)!.userBlocked,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.grey600,
                fontSize: 14,
                fontWeight: FontWeight.w500)));
  }

  Widget _buildIcon(Icon icon, Function()? onPressed, {Color? color}) {
    return Container(
        decoration: BoxDecoration(
            color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Center(
          child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              color: color,
              child: icon),
        ));
  }

  String prepareHintText() {
    if (widget.controller.isChannel) {
      String name = widget.groupInfoNotifier!.value.groupInfo.name;
      widget.groupInfoNotifier!.addListener(() {
        name = widget.groupInfoNotifier!.value.groupInfo.name;
      });
      return "${AppLocalizations.of(context)!.chatTextFieldHint} #$name";
    } else if (widget.controller.isUser) {
      String name = widget.userInfoNotifier!.value.userInfo.name;
      widget.userInfoNotifier!.addListener(() {
        name = widget.userInfoNotifier!.value.userInfo.name;
      });
      return "${AppLocalizations.of(context)!.chatTextFieldHint} @$name";
    }
    return "";
  }

  Widget _buildTextField() {
    return ChatTextField(
      focusNode: widget._focusNode,
      mentionsKey: widget.mentionsKey,
      groupInfoMNotifier: widget.groupInfoNotifier,
      userInfoMNotifier: widget.userInfoNotifier,
      reactionDataNotifier: _reactionDataNotifier,
    );
  }

  Widget _buildUserTextField() {
    return ValueListenableBuilder<UserInfoM>(
        valueListenable: widget.userInfoNotifier!,
        builder: (context, userInfoM, _) {
          // if (userInfoM.contactStatus == ContactInfoStatus.blocked.name) {
          //   return _buildBlockedBottomBar();
          // }
          return _buildTextField();
        });
  }

  /// Copy texts to clipboard.
  ///
  /// Only executes for text and markdown messages.
  void _onTapCopy(ChatMsgM chatMsgM) async {
    assert(chatMsgM.detailContentType == MsgContentType.text ||
        chatMsgM.detailContentType == MsgContentType.markdown);

    String content =
        chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? "";
    if (chatMsgM.detailContentType == MsgContentType.text) {
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
    assert(chatMsgM.detailContentType != MsgContentType.archive);

    List<int> midList = [];
    midList.add(chatMsgM.mid);
    try {
      final savedApi = SavedApi();
      await savedApi.createSaved(midList).then((value) {
        Navigator.of(context).pop();
      });
    } catch (e) {
      App.logger.severe(e);
      Navigator.of(context).pop();
    }
  }

  void _onTapTileForward(MsgTileData tileData) async {
    Navigator.of(context).pop();

    final chatMsgM = tileData.chatMsgMNotifier.value;

    if (chatMsgM.detailContentType == MsgContentType.archive) {
      String? archiveId = chatMsgM.msgNormal?.content;

      if (archiveId == null) return;

      await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
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
                  Future.delayed(const Duration(seconds: 2)).then((value) {
                    buttonStatus.value = ButtonStatus.normal;
                  });
                },
              ),
            );
          });
      return;
    }

    selectedMsgMap.addAll({chatMsgM.localMid: tileData.chatMsgMNotifier});

    _forward();
  }

  void _forward() async {
    final midList = selectedMsgMap.values.map((e) => e.value.mid).toList();
    if (midList.isEmpty) {
      return;
    }

    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
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
                Future.delayed(const Duration(seconds: 2)).then((value) {
                  buttonStatus.value = ButtonStatus.normal;
                });
              },
            ),
          );
        });

    selectedMsgMap.clear();
    widget.controller.clearMsgsSelection();
    selectEnabled.value = false;
  }

  void _createSavedItem() async {
    final midList = selectedMsgMap.values.map((e) => e.value.mid).toList();
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

    selectedMsgMap.clear();
    widget.controller.clearMsgsSelection();
    selectEnabled.value = false;
  }

  void _batchDelete() async {
    if (selectedMsgMap.values.isEmpty) {
      return;
    }

    for (var msgMNotifier in selectedMsgMap.values) {
      await delete(msgMNotifier.value);
    }

    selectedMsgMap.clear();
    widget.controller.clearMsgsSelection();
    selectEnabled.value = false;
  }

  Future<bool> delete(ChatMsgM old) async {
    try {
      await MessageApi().delete(old.mid).then((response) async {
        if (response.statusCode == 200 || (old.status != MsgStatus.success)) {
          // successfully deleted or failed to send.

          FileHandler.singleton.deleteWithChatMsgM(old);
          AudioFileHandler().deleteWithChatMsgM(old);

          ChatMsgDao().deleteMsgByLocalMid(old).then((successful) async {
            if (successful) {
              widget.controller.onDeleteWithLocalMid(old.localMid);

              int curMaxMid;

              if (old.isGroupMsg) {
                curMaxMid = await ChatMsgDao().getChannelMaxMid(old.gid);
              } else {
                curMaxMid = await ChatMsgDao().getDmMaxMid(old.dmUid);
              }
              if (curMaxMid > -1) {
                final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

                if (msg != null) {
                  App.app.chatService.fireMsg(msg, true, snippetOnly: true);
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((value) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildVoceMsgList() {
    return Expanded(
      child: Scrollbar(
        controller: _scrollController,
        child: AnimatedList(
          key: widget.controller.listKey,
          controller: _scrollController,
          reverse: true,
          initialItemCount: widget.controller.tileDataList.length + 1,
          itemBuilder: (context, index, animation) {
            if (index == widget.controller.tileDataList.length) {
              widget.controller.reachesEnd.then((reachesEnd) {
                if (!reachesEnd) {
                  widget.controller.loadHistory();
                }
              });
              if (widget.controller.isChannel) {
                return ChannelStart(widget.groupInfoNotifier!,
                    widget.controller.isLoadingHistory);
              } else {
                return const SizedBox.shrink();
              }
            }
            final tileData = widget.controller.tileDataList[index];

            // return VoceContextMenu(
            //   actions: _buildPressDownActions(tileData),
            //   child:
            //       SingleChildScrollView(child: VoceMsgTile(tileData: tileData)),
            // );

            final ani = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
              parent: animation,
              curve: Interval(
                0.5,
                1,
                curve: Curves.easeInOut,
              ),
            ));

            final msgTile = VoceMsgTile(
              tileData: tileData,
              sizeFactor: ani,
              enableSelection: selectEnabled,
              onSelectChange: (tileData, selected) {
                final chatMsgM = tileData.chatMsgMNotifier;
                if (selected) {
                  // UI is selected, need to also add it to the message map
                  selectedMsgMap.addAll({chatMsgM.value.localMid: chatMsgM});
                } else {
                  selectedMsgMap.remove(chatMsgM.value.localMid);
                }

                selectedMsgCantMultipleArchive.value =
                    selectedMsgMap.values.any(
                  (element) {
                    return element.value.isArchiveMsg ||
                        element.value.isAudioMsg ||
                        element.value.status != MsgStatus.success;
                  },
                );
              },
            );

            return GestureDetector(
                key: msgTile.key,
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8))),
                    builder: (context) {
                      return MsgActionsSheet(
                          existingReactions: tileData
                              .chatMsgMNotifier.value.reactionData?.reactionSet,
                          onReaction: (reaction) {
                            VoceSendService()
                                .sendReaction(
                                    tileData.chatMsgMNotifier.value, reaction)
                                .then((succeed) {
                              Navigator.pop(context);
                              if (!succeed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            AppLocalizations.of(context)!
                                                .networkError)));
                              }
                            });
                          },
                          chatMsgM: tileData.chatMsgMNotifier.value,
                          actions: _buildOldLongPressActions(tileData));
                    },
                  );
                },
                child: msgTile);
          },
        ),
      ),
    );
  }

  /// Build the actions for message tile long press gesture.
  ///
  /// It is an old version of [_buildPressDownActions]. To be replaced after
  /// the development and UI debug of [VoceContextMenu] finishes.
  List<MsgActionTile> _buildOldLongPressActions(MsgTileData tileData) {
    final isSuccessSent = tileData.status.value == MsgStatus.success;
    final isSelf = SharedFuncs.isSelf(tileData.userInfoM.uid);
    final isAdmin = tileData.userInfoM.userInfo.isAdmin;
    final isChannelOwner =
        SharedFuncs.isSelf(widget.groupInfoNotifier?.value.groupInfo.owner);
    final chatMsgM = tileData.chatMsgMNotifier.value;

    List<MsgActionTile> actions = [];

    // Reply
    if (isSuccessSent) {
      actions.add(MsgActionTile(
          icon: AppIcons.reply,
          title: AppLocalizations.of(context)!.reply,
          onTap: () {
            Navigator.pop(context);
            setReactionData(tileData, ReactionType.reply);
          }));
    }

    // Edit
    if (isSuccessSent && isSelf && chatMsgM.isTextMsg) {
      actions.add(MsgActionTile(
          icon: AppIcons.edit,
          title: AppLocalizations.of(context)!.edit,
          onTap: () {
            Navigator.pop(context);
            setReactionData(tileData, ReactionType.edit);
          }));
    }

    // Copy
    if (chatMsgM.isTextMsg || chatMsgM.isMarkdownMsg) {
      actions.add(MsgActionTile(
          icon: AppIcons.copy,
          title: AppLocalizations.of(context)!.copy,
          onTap: () => _onTapCopy(chatMsgM)));
    }

    // Pin
    if ((isAdmin || isChannelOwner) && chatMsgM.isGroupMsg && isSuccessSent) {
      final isPinned = widget.groupInfoNotifier?.value.groupInfo.pinnedMessages
              .indexWhere((e) => e.mid == chatMsgM.mid) ??
          -1;
      actions.add(MsgActionTile(
          icon: AppIcons.pin,
          title: isPinned > -1
              ? AppLocalizations.of(context)!.unpin
              : AppLocalizations.of(context)!.pin,
          onTap: () => _onTapPin(chatMsgM, isPinned == -1)));
    }

    // Save
    if (!chatMsgM.isArchiveMsg && !chatMsgM.isAudioMsg && isSuccessSent) {
      actions.add(MsgActionTile(
          icon: AppIcons.bookmark,
          title: AppLocalizations.of(context)!.save,
          onTap: () => _onTapSave(chatMsgM)));
    }

    // Forward
    if (!chatMsgM.isAudioMsg && isSuccessSent) {
      actions.add(MsgActionTile(
          icon: AppIcons.forward,
          title: AppLocalizations.of(context)!.forward,
          onTap: () => _onTapTileForward(tileData)));
    }

    // Select
    actions.add(MsgActionTile(
        icon: AppIcons.select,
        title: AppLocalizations.of(context)!.select,
        onTap: () {
          Navigator.pop(context);
          selectEnabled.value = true;
        }));

    // Delete
    if (isSelf || isAdmin || isChannelOwner) {
      actions.add(MsgActionTile(
          icon: AppIcons.delete,
          title: AppLocalizations.of(context)!.delete,
          onTap: () {
            Navigator.of(context).pop();
            delete(chatMsgM);
          }));
    }

    return actions;
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

  void setReactionData(MsgTileData? tileData, ReactionType reactionType) {
    _reactionDataNotifier.value =
        ChatFieldReactionData(reactionType: reactionType, tileData: tileData);
  }
}
