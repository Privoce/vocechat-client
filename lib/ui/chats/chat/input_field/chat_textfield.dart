import 'dart:convert';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/models/ui_models/msg_tile_data.dart';
import 'package:vocechat_client/services/voce_send_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/voice_button.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/tile_image_bubble.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum InputType { text, voice }

class ChatTextField extends StatefulWidget {
  final ValueNotifier<GroupInfoM>? groupInfoMNotifier;
  final ValueNotifier<UserInfoM>? userInfoMNotifier;
  final FocusNode focusNode;
  final GlobalKey<AppMentionsState> mentionsKey;

  final ValueNotifier<ChatFieldReactionData> reactionDataNotifier;

  final _hintColor = const Color.fromRGBO(152, 162, 179, 1);
  final _bgColor = const Color.fromRGBO(249, 249, 249, 0.94);
  final _height = 40.0;

  ChatTextField({
    Key? key,
    this.groupInfoMNotifier,
    this.userInfoMNotifier,
    required this.focusNode,
    required this.mentionsKey,
    required this.reactionDataNotifier,
  }) : super(key: key);

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  late ValueNotifier<Set<UserInfoM>> memberSetNotifier = ValueNotifier({});

  List<Map<String, dynamic>> memberList = <Map<String, dynamic>>[];
  TextEditingController controller = TextEditingController();

  ValueNotifier<InputType> inputType = ValueNotifier(InputType.text);
  final ValueNotifier<VoiceButtonType> voiceButtonState =
      ValueNotifier(VoiceButtonType.normal);
  ValueNotifier<bool> hasText = ValueNotifier(false);

  late final ValueNotifier<InputBarInfo> inputBarInfoNotifier;

  Set markupSet = {};

  bool get isChannel => widget.groupInfoMNotifier != null;
  bool get isUser => widget.userInfoMNotifier != null;

  @override
  void initState() {
    super.initState();

    inputBarInfoNotifier = ValueNotifier(InputBarInfo(
        draft: prepareDraft(isChannel), hintText: prepareHintText(isChannel)));

    widget.groupInfoMNotifier?.addListener(onGroupInfoMChange);
    widget.userInfoMNotifier?.addListener(onUserInfoMChange);
    widget.reactionDataNotifier.addListener(onReactionDataChange);
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();

    widget.groupInfoMNotifier?.removeListener(onGroupInfoMChange);
    widget.userInfoMNotifier?.removeListener(onUserInfoMChange);
    widget.reactionDataNotifier.removeListener(onReactionDataChange);

    markupSet = {};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildReply(context),
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            decoration: BoxDecoration(
                color: widget._bgColor, borderRadius: BorderRadius.circular(5)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildInputBar(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return FutureBuilder(
      future: memberListProcess(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return ValueListenableBuilder<InputBarInfo>(
            valueListenable: inputBarInfoNotifier,
            builder: (context, info, _) {
              return AppMentions(
                defaultText: info.draft,
                key: widget.mentionsKey,
                enableMention: widget.groupInfoMNotifier != null,
                hasText: hasText,
                uid: widget.userInfoMNotifier?.value.uid,
                gid: widget.groupInfoMNotifier?.value.gid,
                // selectionControls: controls,
                voiceButtonState: voiceButtonState,
                inputFieldType: inputType,
                contextMenuBuilder: _buildContextMenu,
                leading: [
                  ValueListenableBuilder<VoiceButtonType>(
                      valueListenable: voiceButtonState,
                      builder: (context, voiceButtonState, _) {
                        switch (voiceButtonState) {
                          case VoiceButtonType.recording:
                            return SizedBox(
                              width: widget._height * 2,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                      width: widget._height,
                                      height: widget._height,
                                      margin: const EdgeInsets.only(right: 4),
                                      child: Icon(Icons.delete,
                                          color: AppColors.grey800)),
                                ],
                              ),
                            );
                          case VoiceButtonType.cancelling:
                            return SizedBox(
                              width: widget._height * 2,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                      width: widget._height,
                                      height: widget._height,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                              widget._height / 2)),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white)),
                                ],
                              ),
                            );

                          default:
                            return Row(
                              children: [
                                SizedBox(
                                  width: widget._height,
                                  height: widget._height,
                                  child: CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: _sendImage,
                                      child: Icon(Icons.image,
                                          color: AppColors.grey800)),
                                ),
                                SizedBox(
                                  width: widget._height,
                                  height: widget._height,
                                  child: CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: _sendFile,
                                      child: Icon(Icons.folder,
                                          color: AppColors.grey800)),
                                ),
                              ],
                            );
                        }
                      }),
                ],
                trailing: [
                  ValueListenableBuilder<InputType>(
                    valueListenable: inputType,
                    builder: (context, inputType, child) {
                      switch (inputType) {
                        case InputType.text:
                          return ValueListenableBuilder<bool>(
                              valueListenable: hasText,
                              builder: (context, hasText, child) {
                                if (hasText) {
                                  return _buildSendButton();
                                } else {
                                  return CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: _micIconPressed,
                                      child: Icon(Icons.mic,
                                          color: AppColors.grey800));
                                }
                              });

                        case InputType.voice:
                          return CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _keyboardButtonPressed,
                              child: Icon(Icons.keyboard,
                                  color: AppColors.grey800));
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
                onChanged: (text) {},
                enabled: true,
                suggestionPosition: SuggestionPosition.top,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                autocorrect: false,
                maxLines: 5,
                minLines: 1,
                maxLength: 2048,
                inputFormatters: [VoceTextInputFormatter(2048)],
                maxLengthEnforcement:
                    MaxLengthEnforcement.truncateAfterCompositionEnds,
                decoration: InputDecoration(
                    isDense: true,
                    counterText: "",
                    hintText: info.hintText,
                    hintMaxLines: 1,
                    hintStyle: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: widget._hintColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(15, 5, 20, 5),
                    border: InputBorder.none),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                focusNode: widget.focusNode,
                onSubmitted: (value) {
                  _sendTxt();
                  widget.focusNode.requestFocus();
                },
                mentions: [
                  Mention(
                      trigger: '@',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                      ),
                      data: memberList,
                      matchAll: false,
                      suggestionBuilder: (data) {
                        return Container(
                          color: AppColors.grey100,
                          width: double.infinity,
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              VoceAvatar(
                                  size: VoceAvatarSize.s36,
                                  isCircle: useCircleAvatar,
                                  name: data['display'] ?? "",
                                  avatarBytes: data["photo"],
                                  backgroundColor: AppColors.primaryBlue,
                                  fontColor: AppColors.grey200),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Text(data['display'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black)),
                              ),
                              if (data['is_admin'] == true)
                                const SizedBox(width: 16),
                              if (data['is_admin'] == true)
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(3, 2, 3, 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[300],
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0)),
                                  ),
                                  child: const Text('Admin',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14)),
                                ),
                              if (data['is_owner'] == true)
                                const SizedBox(width: 16),
                              if (data['is_owner'] == true)
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(3, 2, 3, 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[300],
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0)),
                                  ),
                                  child: const Text('Owner',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14)),
                                )
                            ],
                          ),
                        );
                      })
                ],
              );
            });
      },
    );
  }

  /// Build the send button
  ///
  /// Will switch between the normal send button, the reply button and the edit
  /// button, listening to the [widget.reactionDataNotifier] value notifier.
  Widget _buildSendButton() {
    return ValueListenableBuilder<ChatFieldReactionData>(
        valueListenable: widget.reactionDataNotifier,
        builder: (context, data, child) {
          switch (data.reactionType) {
            case ReactionType.reply:
              return SizedBox(
                height: widget._height,
                width: widget._height,
                child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _sendReply,
                    child: Icon(Icons.send, color: AppColors.grey800)),
              );
            case ReactionType.edit:
              return SizedBox(
                height: widget._height,
                width: widget._height * 2,
                child: Row(
                  children: [
                    FittedBox(
                      child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _cancelEdit,
                          child: Icon(Icons.close, color: AppColors.grey800)),
                    ),
                    FittedBox(
                      child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _sendEdit,
                          child: Icon(Icons.check_circle,
                              color: AppColors.grey800)),
                    ),
                  ],
                ),
              );
            default:
              return SizedBox(
                height: widget._height,
                width: widget._height,
                child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _sendTxt,
                    child: Icon(Icons.send, color: AppColors.grey800)),
              );
          }
        });
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState state) {
    return FutureBuilder<Uint8List?>(
      future: _getClipboardImage(),
      builder: (context, snapshot) {
        final List<ContextMenuButtonItem> buttonItems =
            state.contextMenuButtonItems;
        // if (snapshot.hasData && snapshot.data!.isNotEmpty) {
        //   buttonItems.add(ContextMenuButtonItem(
        //     type: ContextMenuButtonType.paste,
        //     onPressed: () => _onPasteImage(),
        //   ));
        // }

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
    );
  }

  // void _onPasteImage() async {
  //   if (Platform.isIOS) {
  //     try {
  //       final image = await _getClipboardImage();
  //       if (image != null) {
  //         _pasteImage(image);
  //       }
  //     } catch (e) {
  //       App.logger.severe(e);
  //     }
  //   }
  //   final TextEditingValue value =
  //       controller.value; // Snapshot the input before using `await`.
  //   final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);

  //   if (data != null) {
  //     final updatedValue = TextEditingValue(
  //         text: value.selection.textBefore(value.text) + (data.text ?? ""),
  //         selection: TextSelection.collapsed(
  //             offset: value.selection.start + (data.text?.length ?? 0)));
  //     controller.value = updatedValue;
  //   }

  //   ContextMenuController.removeAny();

  //   // delegate.bringIntoView(delegate.textEditingValue.selection.extent);
  //   // delegate.hideToolbar();
  // }

  // void _pasteImage(Uint8List imageBytes) async {
  //   final context = navigatorKey.currentContext;
  //   if (context == null) return;

  //   final imageWidget = Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Image.memory(imageBytes),
  //   );
  //   showAppAlert(
  //       context: context,
  //       title: AppLocalizations.of(context)!.appTextSelectionControlPasteImage,
  //       contentWidget: imageWidget,
  //       actions: [
  //         AppAlertDialogAction(
  //             text: AppLocalizations.of(context)!.cancel,
  //             action: (() => Navigator.of(context).pop()))
  //       ],
  //       primaryAction: AppAlertDialogAction(
  //           text: AppLocalizations.of(context)!.send,
  //           action: () {
  //             // return _send(path, type, uuid());
  //             // SendService.singleton.sendMessage(uuid(), "", SendType.file,
  //             //     blob: imageBytes,
  //             //     gid: widget.groupInfoMNotifier?.value.gid,
  //             //     uid: widget.userInfoMNotifier?.value.uid);
  //             if (isChannel) {
  //               VoceSendService().sendChannelFile(widget.groupInfoMNotifier!.value.gid, path)
  //             }
  //             Navigator.of(context).pop();
  //           }));
  // }

  Widget _buildReply(BuildContext context) {
    return ValueListenableBuilder<ChatFieldReactionData>(
      valueListenable: widget.reactionDataNotifier,
      builder: (context, data, child) {
        switch (data.reactionType) {
          case ReactionType.reply:
            final name = data.tileData?.name ?? "";
            return ValueListenableBuilder<ChatMsgM>(
              valueListenable: data.tileData!.chatMsgMNotifier,
              builder: (context, repliedMsgM, child) {
                switch (repliedMsgM.detailContentTypeStr) {
                  case typeText:
                  case typeMarkdown:
                    return FutureBuilder<String>(
                        future: SharedFuncs.parseMention(
                            repliedMsgM.reactionData?.hasEditedText == true
                                ? repliedMsgM.reactionData!.editedText!
                                : json.decode(repliedMsgM.detail)["content"]),
                        builder: (context, snapshot) {
                          return _buildReplyWithLeading(
                              snapshot.data ?? "", name, null);
                        });
                  case typeFile:
                    if (repliedMsgM.isImageMsg) {
                      // final content = Image.file(widget.repliedImageFile!, height: 30);
                      final content = VoceImageBubble.reply(
                          imageFile: data.tileData?.imageFile,
                          getImageList: () =>
                              VoceTileImageBubble.defaultGetImageList(
                                  repliedMsgM));
                      return _buildReplyWithLeading(null, name, content);
                    } else {
                      final fileIcon = SvgPicture.asset(
                          "assets/images/file.svg",
                          width: 20,
                          height: 20);
                      return _buildReplyWithLeading(null, name, fileIcon);
                    }
                  case typeArchive:
                    return _buildReplyWithLeading(
                        AppLocalizations.of(context)!.archive, name, null);
                  case typeAudio:
                    return _buildReplyWithLeading(
                        AppLocalizations.of(context)!.audioMessage, name, null);
                  default:
                    return FutureBuilder<String>(
                        future: SharedFuncs.parseMention(
                            json.decode(repliedMsgM.detail)["content"]),
                        builder: (context, snapshot) {
                          return _buildReplyWithLeading(
                              snapshot.data ?? "", name, null);
                        });
                }
              },
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildReplyWithLeading(
      String? contentStr, String? name, Widget? content) {
    return Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(minHeight: 30, maxHeight: 60),
        padding: const EdgeInsets.fromLTRB(20, 5, 10, 5),
        color: AppColors.greyNeutral,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                            style: TextStyle(
                                color: AppColors.coolGrey500,
                                fontWeight: FontWeight.w400,
                                fontSize: 15),
                            children: [
                              TextSpan(
                                  text:
                                      "${AppLocalizations.of(context)!.replyingTo} "),
                              if (name != null && name.isNotEmpty)
                                TextSpan(
                                  text: "$name   ",
                                  style: TextStyle(
                                      color: AppColors.coolGrey500,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                              if (contentStr != null)
                                TextSpan(
                                    text: contentStr,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.grey97)),
                            ])),
                  ),
                  if (content != null) content
                ],
              ),
            ),
            CupertinoButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerRight,
                onPressed: resetInputBar,
                child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(Icons.close, color: AppColors.grey800)))
          ],
        ));
  }

  /// Reset the input bar to normal state.
  ///
  /// Only resets the state. Won't clear inputfield.
  void resetInputBar() {
    widget.reactionDataNotifier.value = ChatFieldReactionData.normal();
  }

  // Change the list structure to accommodate mentions data
  Future<List<Map<String, dynamic>>> memberListProcess() async {
    if (widget.groupInfoMNotifier == null) return [];

    final userInfoList = await getMemberList();
    List<Map<String, dynamic>> userInfoMapList = [];

    for (final userInfoM in userInfoList) {
      Map<String, dynamic> userInfoMap = {};
      userInfoMap.addAll({"uid": userInfoM.uid});
      // userInfoMap.addAll({"photo": userInfoM.avatarBytes});
      userInfoMap.addAll({"display": userInfoM.userInfo.name});
      userInfoMap.addAll({"is_admin": userInfoM.userInfo.isAdmin});
      userInfoMap.addAll({
        "is_owner":
            widget.groupInfoMNotifier?.value.groupInfo.owner == userInfoM.uid
      });

      userInfoMapList.add(userInfoMap);
    }

    memberList = userInfoMapList;
    return memberList;
  }

  Future<List<UserInfoM>> getMemberList() async {
    final members = (await GroupInfoDao().getUserListByGid(
            widget.groupInfoMNotifier!.value.gid,
            widget.groupInfoMNotifier!.value.groupInfo.isPublic,
            widget.groupInfoMNotifier!.value.groupInfo.members ?? [],
            batchSize: 0)) ??
        [];
    memberSetNotifier.value = Set.from(members);
    return members;
  }

  final taskQueue = TaskQueue(enableStatusDisplay: false);

  Future<bool> requestPermission() async {
    late PermissionStatus status;

    if (Platform.isIOS) {
      status = await Permission.photosAddOnly.request();
    } else {
      status = await Permission.storage.request();
    }

    if (status != PermissionStatus.granted && mounted) {
      showAppAlert(
          context: context,
          title: AppLocalizations.of(context)!.chatTextFieldPhotoPermission,
          content:
              AppLocalizations.of(context)!.chatTextFieldPhotoPermissionContent,
          actions: [
            AppAlertDialogAction(
                text: AppLocalizations.of(context)!.ok,
                action: () => Navigator.of(context).pop())
          ]);
    } else {
      return true;
    }
    return false;
  }

  void _sendImage() async {
    FocusScope.of(context).unfocus();

    // assets list
    List<AssetEntity> assets = <AssetEntity>[];

    // config picker assets max count
    const int maxAssetsCount = 9;
    final List<AssetEntity>? assetsResult = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        limitedPermissionOverlayPredicate: (s) =>
            s == PermissionState.authorized,
        maxAssets: maxAssetsCount,
        specialItemPosition: SpecialItemPosition.prepend,
        specialItemBuilder: (
          BuildContext context,
          AssetPathEntity? path,
          int length,
        ) {
          if (path?.isAll != true) {
            return null;
          }
          return Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                bool cameraPermissionDenied =
                    (await Permission.camera.request()) !=
                        PermissionStatus.granted;
                bool microphonePermissionDenied =
                    (await Permission.microphone.request()) !=
                        PermissionStatus.granted;

                if (cameraPermissionDenied || microphonePermissionDenied) {
                  showAppAlert(
                      context: context,
                      title: AppLocalizations.of(context)!
                          .chatTextFieldCameraMicrophonePermission,
                      content: AppLocalizations.of(context)!
                          .chatTextFieldCameraMicrophonePermissionContent,
                      actions: [
                        AppAlertDialogAction(
                            text: AppLocalizations.of(context)!.ok,
                            action: () => Navigator.of(context).pop())
                      ]);
                } else {
                  Feedback.forTap(context);
                  final AssetEntity? result = await pickFromCamera(context);
                  if (result != null) {
                    Navigator.of(context).pop(<AssetEntity>[...assets, result]);
                  }
                }
              },
              child: const Center(
                child: Icon(Icons.camera_enhance, size: 42.0),
              ),
            ),
          );
        },
      ),
    );

    if (assetsResult == null) return;

    Future.forEach(assetsResult, (AssetEntity element) async {
      final File? file = await element.originFile;
      final String? path = file?.path;

      if (widget.userInfoMNotifier != null && path != null && path.isNotEmpty) {
        VoceSendService()
            .sendUserFile(widget.userInfoMNotifier!.value.uid, path);
      } else if (widget.groupInfoMNotifier != null &&
          path != null &&
          path.isNotEmpty) {
        VoceSendService()
            .sendChannelFile(widget.groupInfoMNotifier!.value.gid, path);
      }
    });
  }

  Future<AssetEntity?> pickFromCamera(BuildContext c) {
    return CameraPicker.pickFromCamera(
      c,
      pickerConfig: const CameraPickerConfig(enableRecording: true),
    );
  }

  void _sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;

    if (path != null && path.isNotEmpty) {
      if (widget.userInfoMNotifier != null) {
        VoceSendService()
            .sendUserFile(widget.userInfoMNotifier!.value.uid, path);
      } else if (widget.groupInfoMNotifier != null) {
        VoceSendService()
            .sendChannelFile(widget.groupInfoMNotifier!.value.gid, path);
      }
    } else {
      // User canceled the picker
      return;
    }
  }

  void _micIconPressed() {
    inputType.value = InputType.voice;
  }

  void _keyboardButtonPressed() {
    inputType.value = InputType.text;
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Iterable<String> _allStringMatches(String text, RegExp regExp) {
    Iterable<Match> matches = regExp.allMatches(text);
    List<Match> listOfMatches = matches.toList();
    // TODO: there must be a better way to get list of Strings out of list of Matches
    Iterable<String> listOfStringMatches = listOfMatches.map((Match m) {
      return m.input.substring(m.start, m.end);
    });

    return listOfStringMatches;
  }

  String _getText() {
    final String markupText =
        widget.mentionsKey.currentState!.controller!.markupText;

    String text = widget.mentionsKey.currentState!.controller!.text;

    RegExp markupRegExp = RegExp(r'\(__([^\(\)]+)__\)');

    Iterable<Match> markupMatches = markupRegExp.allMatches(markupText);

    for (Match m in markupMatches) {
      String? match = m.group(1)?.trim();
      markupSet.add(match);
    }

    for (var markupItem in markupSet.toList()) {
      for (var item in memberList) {
        if (item.containsValue(markupItem)) {
          text = text.replaceAll('@$markupItem ', ' @${item['uid']} ');
        }
      }
    }
    return text;
  }

  void _sendTxt() async {
    final content = _getText();

    if (content.trim().isNotEmpty) {
      widget.mentionsKey.currentState!.controller?.clear();

      if (widget.groupInfoMNotifier != null) {
        VoceSendService()
            .sendChannelText(widget.groupInfoMNotifier!.value.gid, content);
      } else if (widget.userInfoMNotifier != null) {
        VoceSendService()
            .sendUserText(widget.userInfoMNotifier!.value.uid, content);
      }
    }
  }

  void _sendEdit() async {
    final content = _getText();

    if (content.trim().isNotEmpty) {
      widget.mentionsKey.currentState!.controller?.clear();

      VoceSendService().sendEdit(
          widget
              .reactionDataNotifier.value.tileData!.chatMsgMNotifier.value.mid,
          content);
    }

    resetInputBar();
  }

  void _cancelEdit() {
    widget.mentionsKey.currentState!.controller?.clear();
    resetInputBar();
  }

  void _sendReply() {
    final content = _getText();

    if (content.trim().isNotEmpty) {
      widget.mentionsKey.currentState!.controller?.clear();
      if (isChannel) {
        VoceSendService().sendChannelReply(
            widget.groupInfoMNotifier!.value.gid,
            widget.reactionDataNotifier.value.tileData!.chatMsgMNotifier.value
                .mid,
            content);
      } else if (isUser) {
        VoceSendService().sendUserReply(
            widget.userInfoMNotifier!.value.uid,
            widget.reactionDataNotifier.value.tileData!.chatMsgMNotifier.value
                .mid,
            content);
      }
    }

    resetInputBar();
  }

  Future<Uint8List?> _getClipboardImage() async {
    try {
      const methodChannel = MethodChannel('clipboard/image');
      final result = await methodChannel.invokeMethod('getClipboardImage');
      if (result != null) return result as Uint8List;
    } on PlatformException catch (e) {
      App.logger.severe(e);
    }

    return null;
  }

  String prepareDraft(bool isChannel) {
    if (isChannel) {
      return widget.groupInfoMNotifier?.value.properties.draft ?? "";
    } else {
      return widget.userInfoMNotifier?.value.properties.draft ?? "";
    }
  }

  String prepareHintText(bool isChannel) {
    String? name = isChannel
        ? widget.groupInfoMNotifier?.value.groupInfo.name
        : widget.userInfoMNotifier?.value.userInfo.name;
    if (name == null || name.isEmpty) {
      return "";
    }

    final context = navigatorKey.currentContext;
    if (context == null) return "";

    if (isChannel) {
      return "${AppLocalizations.of(context)!.chatTextFieldHint} #$name";
    } else {
      return "${AppLocalizations.of(context)!.chatTextFieldHint} @$name";
    }
  }

  void onGroupInfoMChange() {
    inputBarInfoNotifier.value = InputBarInfo(
      draft: prepareDraft(true),
      hintText: prepareHintText(true),
    );
  }

  void onUserInfoMChange() {
    inputBarInfoNotifier.value = InputBarInfo(
      draft: prepareDraft(false),
      hintText: prepareHintText(false),
    );
  }

  void onReactionDataChange() {
    if (widget.reactionDataNotifier.value.reactionType == ReactionType.edit) {
      final targetMsg =
          widget.reactionDataNotifier.value.tileData?.chatMsgMNotifier.value;

      widget.mentionsKey.currentState?.controller?.text =
          targetMsg?.reactionData?.hasEditedText == true
              ? targetMsg!.reactionData!.editedText!
              : targetMsg?.msgNormal?.content ??
                  targetMsg?.msgReply?.content ??
                  "";
    }
  }
}

class ChatFieldReactionData {
  MsgTileData? tileData;
  ReactionType reactionType;

  ChatFieldReactionData({this.tileData, required this.reactionType});

  ChatFieldReactionData.normal()
      : tileData = null,
        reactionType = ReactionType.normal;
}

class InputBarInfo extends Equatable {
  final String draft;
  final String hintText;

  InputBarInfo({required this.draft, required this.hintText});

  @override
  List<Object?> get props => [draft, hintText];
}

enum ReactionType { reply, edit, normal }
