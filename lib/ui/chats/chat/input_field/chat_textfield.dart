import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/send_service.dart';
import 'package:vocechat_client/services/task_queue.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:voce_widgets/voce_widgets.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatTextField extends StatefulWidget {
  final GroupInfoM? groupInfoM;
  final UserInfoM? userInfoM;
  final String hintText;
  final FocusNode focusNode;
  String? draft;
  final GlobalKey<AppMentionsState> mentionsKey;
  final Future<bool> Function(String text, SendType type) sendText;
  final Future<bool> Function(String path, SendType type) onSendFile;
  final ValueNotifier<SendType> sendBtnType;
  final ChatMsgM? repliedMsgM;
  final UserInfoM? repliedUser;
  final File? repliedImageFile;
  final VoidCallback onCancelReply;
  final _hintColor = Color.fromRGBO(152, 162, 179, 1);
  final _bgColor = Color.fromRGBO(249, 249, 249, 0.94);
  final _height = 40.0;

  ChatTextField(
      {Key? key,
      this.draft,
      required this.groupInfoM,
      this.userInfoM,
      required this.focusNode,
      required this.mentionsKey,
      required this.hintText,
      required this.sendText,
      required this.onSendFile,
      required this.sendBtnType,
      this.repliedMsgM,
      this.repliedUser,
      this.repliedImageFile,
      required this.onCancelReply})
      : super(key: key);

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  late ValueNotifier<Set<UserInfoM>> memberSetNotifier = ValueNotifier({});
  final selectedMention = ValueNotifier<LengthMap?>(null);
  List<Map<String, dynamic>> memberList = <Map<String, dynamic>>[];
  TextEditingController controller = TextEditingController();

  Set markupSet = {};
  @override
  void initState() {
    super.initState();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
    markupSet = {};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildReply(context),
        Container(
          constraints: BoxConstraints(minHeight: 56),
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            decoration: BoxDecoration(
                color: widget._bgColor, borderRadius: BorderRadius.circular(5)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTextField(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return FutureBuilder(
      future: memberListProcess(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return AppMentions(
          defaultText: widget.draft,
          key: widget.mentionsKey,
          enableMention: widget.groupInfoM != null,
          // selectionControls: controls,
          contextMenuBuilder: _buildContextMenu,
          leading: [
            SizedBox(
              width: widget._height,
              height: widget._height,
              child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _sendImage,
                  child: Icon(Icons.image, color: AppColors.grey800)),
            ),
            SizedBox(
              width: widget._height,
              height: widget._height,
              child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _sendFile,
                  child: Icon(Icons.folder, color: AppColors.grey800)),
            ),
          ],
          trailing: [
            ValueListenableBuilder<SendType>(
                valueListenable: widget.sendBtnType,
                builder: (context, value, child) {
                  switch (value) {
                    case SendType.normal:
                      return SizedBox(
                        height: widget._height,
                        width: widget._height,
                        child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _sendTxt,
                            child: Icon(Icons.send, color: AppColors.grey800)),
                      );
                    case SendType.reply:
                      return SizedBox(
                        height: widget._height,
                        width: widget._height,
                        child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _sendReply,
                            child: Icon(Icons.send, color: AppColors.grey800)),
                      );
                    case SendType.edit:
                      return SizedBox(
                        height: widget._height,
                        width: widget._height * 2,
                        child: Row(
                          children: [
                            FittedBox(
                              child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    _cancelEdit();
                                  },
                                  child: Icon(Icons.close,
                                      color: AppColors.grey800)),
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
                            child: Icon(Icons.send)),
                      );
                  }
                })
          ],
          onChanged: (text) {},
          enabled: true,
          suggestionPosition: SuggestionPosition.Top,
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
              hintText: widget.hintText,
              hintMaxLines: 1,
              hintStyle: TextStyle(
                overflow: TextOverflow.ellipsis,
                color: widget._hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: EdgeInsets.fromLTRB(15, 5, 20, 5),
              border: InputBorder.none),
          style: TextStyle(
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
                style: const TextStyle(
                  color: Colors.blue,
                ),
                data: memberList,
                matchAll: false,
                suggestionBuilder: (data) {
                  return Container(
                    color: AppColors.grey100,
                    width: double.infinity,
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        UserAvatar(
                            avatarSize: VoceAvatarSize.s36,
                            uid: data['uid'] ?? -1,
                            name: data['display'] ?? "",
                            avatarBytes: data["photo"]),
                        SizedBox(width: 16),
                        Flexible(
                          child: Text(data['display'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                        if (data['is_admin'] == true) SizedBox(width: 16),
                        if (data['is_admin'] == true)
                          Container(
                            padding: EdgeInsets.fromLTRB(3, 2, 3, 2),
                            decoration: BoxDecoration(
                              color: Colors.green[300],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Text('Admin',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ),
                        if (data['is_owner'] == true) SizedBox(width: 16),
                        if (data['is_owner'] == true)
                          Container(
                            padding: EdgeInsets.fromLTRB(3, 2, 3, 2),
                            decoration: BoxDecoration(
                              color: Colors.green[300],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Text('Owner',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          )
                      ],
                    ),
                  );
                })
          ],
        );
      },
    );
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState state) {
    // return AdaptiveTextSelectionToolbar.buttonItems(
    //   anchors: state.contextMenuAnchors,
    //   buttonItems: buttonItems,
    // );

    return FutureBuilder<Uint8List?>(
      future: _getClipboardImage(),
      builder: (context, snapshot) {
        final List<ContextMenuButtonItem> buttonItems =
            state.contextMenuButtonItems;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          // state.clipboardStatus?.value = ClipboardStatus.pasteable;

          // final index = buttonItems.indexWhere(
          //     (element) => element.type == ContextMenuButtonType.paste);
          // if (index != -1) {
          //   final replacePasteButton = ContextMenuButtonItem(
          //     // type: ContextMenuButtonType.paste,,
          //     onPressed: () => _onPasteImage(),
          //   );
          //   buttonItems[index] = replacePasteButton;
          // }
          buttonItems.add(ContextMenuButtonItem(
            type: ContextMenuButtonType.paste,
            onPressed: () => _onPasteImage(),
          ));
        }

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
    );
  }

  void _onPasteImage() async {
    if (Platform.isIOS) {
      try {
        final image = await _getClipboardImage();
        if (image != null) {
          _pasteImage(image);
        }
      } catch (e) {
        App.logger.severe(e);
      }
    }
    final TextEditingValue value =
        controller.value; // Snapshot the input before using `await`.
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data != null) {
      final updatedValue = TextEditingValue(
          text: value.selection.textBefore(value.text) + (data.text ?? ""),
          selection: TextSelection.collapsed(
              offset: value.selection.start + (data.text?.length ?? 0)));
      controller.value = updatedValue;
    }

    ContextMenuController.removeAny();

    // delegate.bringIntoView(delegate.textEditingValue.selection.extent);
    // delegate.hideToolbar();
  }

  void _pasteImage(Uint8List imageBytes) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final imageWidget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.memory(imageBytes),
    );
    showAppAlert(
        context: context,
        title: AppLocalizations.of(context)!.appTextSelectionControlPasteImage,
        contentWidget: imageWidget,
        actions: [
          AppAlertDialogAction(
              text: AppLocalizations.of(context)!.cancel,
              action: (() => Navigator.of(context).pop()))
        ],
        primaryAction: AppAlertDialogAction(
            text: AppLocalizations.of(context)!.send,
            action: () {
              // return _send(path, type, uuid());
              SendService.singleton.sendMessage(uuid(), "", SendType.file,
                  blob: imageBytes,
                  gid: widget.groupInfoM?.gid,
                  uid: widget.userInfoM?.uid);
              Navigator.of(context).pop();
            }));
  }

  Widget _buildReply(BuildContext context) {
    if (widget.repliedMsgM != null && widget.repliedUser != null) {
      switch (widget.repliedMsgM!.detailContentType) {
        case typeText:
        case typeMarkdown:
          return FutureBuilder<String>(
              future: SharedFuncs.parseMention(
                  json.decode(widget.repliedMsgM!.detail)["content"]),
              builder: (context, snapshot) {
                return _buildReplyWithLeading(snapshot.data ?? "", null);
              });
        case typeFile:
          if (widget.repliedMsgM!.isImageMsg) {
            final content = Image.file(widget.repliedImageFile!, height: 30);
            return _buildReplyWithLeading(null, content);
          } else {
            final fileIcon = SvgPicture.asset("assets/images/file.svg",
                width: 20, height: 20);
            return _buildReplyWithLeading(null, fileIcon);
          }
        case typeArchive:
          return _buildReplyWithLeading("[Archive]", null);

        default:
          return FutureBuilder<String>(
              future: SharedFuncs.parseMention(
                  json.decode(widget.repliedMsgM!.detail)["content"]),
              builder: (context, snapshot) {
                return _buildReplyWithLeading(snapshot.data ?? "", null);
              });
      }
    }
    return SizedBox.shrink();
  }

  Widget _buildReplyWithLeading(String? contentStr, Widget? content) {
    return Container(
        width: double.maxFinite,
        constraints: BoxConstraints(minHeight: 30, maxHeight: 60),
        padding: EdgeInsets.fromLTRB(20, 5, 10, 5),
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
                              TextSpan(
                                text: "${widget.repliedUser!.userInfo.name}   ",
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
                onPressed: () {
                  widget.onCancelReply();
                },
                child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: Icon(Icons.close, color: AppColors.grey800)))
          ],
        ));
  }

  // Change the list structure to accommodate mentions data
  Future<List<Map<String, dynamic>>> memberListProcess() async {
    if (widget.groupInfoM == null) return [];

    final userInfoList = await getMemberList();
    List<Map<String, dynamic>> userInfoMapList = [];

    for (final userInfoM in userInfoList) {
      Map<String, dynamic> userInfoMap = {};
      userInfoMap.addAll({"uid": userInfoM.uid});
      userInfoMap.addAll({"photo": userInfoM.avatarBytes});
      userInfoMap.addAll({"display": userInfoM.userInfo.name});
      userInfoMap.addAll({"is_admin": userInfoM.userInfo.isAdmin});
      userInfoMap.addAll(
          {"is_owner": widget.groupInfoM?.groupInfo.owner == userInfoM.uid});

      userInfoMapList.add(userInfoMap);
    }

    memberList = userInfoMapList;
    return memberList;
  }

  Future<List<UserInfoM>> getMemberList() async {
    final members = (await GroupInfoDao().getUserListByGid(
            widget.groupInfoM!.gid,
            widget.groupInfoM!.groupInfo.isPublic,
            widget.groupInfoM!.groupInfo.members ?? [],
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

      widget.onSendFile(path!, SendType.file);
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

    if (result?.files.single.path != null) {
      await widget.onSendFile(result!.files.single.path!, SendType.file);
      setState(() {});
    } else {
      // User canceled the picker
      return;
    }
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
    final msg = _getText();

    if (msg.trim().isNotEmpty) {
      widget.mentionsKey.currentState!.controller?.clear();
      widget.sendText(msg, SendType.normal);
    }
  }

  void _sendEdit() async {
    final msg = widget.mentionsKey.currentState!.controller?.text;

    if (msg!.trim().isNotEmpty) {
      widget.mentionsKey.currentState!.controller?.clear();
      widget.sendText(msg, SendType.edit);
    }
  }

  void _cancelEdit() {
    widget.mentionsKey.currentState!.controller?.clear();
    widget.sendText("", SendType.cancel);
  }

  void _sendReply() {
    final msg = _getText();

    if (msg.trim().isNotEmpty) {
      widget.mentionsKey.currentState!.controller?.clear();
      widget.sendText(msg, SendType.reply);
    }
  }

  Future<Uint8List?> _getClipboardImage() async {
    try {
      final methodChannel = MethodChannel('clipboard/image');
      final result = await methodChannel.invokeMethod('getClipboardImage');
      if (result != null) return result as Uint8List;
    } on PlatformException catch (e) {
      App.logger.severe(e);
    }

    return null;
  }
}
