import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/org_dao/chat_server.dart';
import 'package:vocechat_client/services/file_handler/user_avatar_handler.dart';
import 'package:vocechat_client/services/voce_chat_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';

class VoceUserAvatar extends StatefulWidget {
  // General variables shared by all constructors
  final double size;
  final bool isCircle;

  /// Only a mannual switch.
  ///
  /// Whether to show depends on the server setting. If both settings are true,
  /// the status will be shown.
  final bool enableOnlineStatus;
  final Color? backgroundColor;

  final UserInfoM? userInfoM;

  final File? file;

  final Uint8List? avatarBytes;

  final String? name;

  final int? uid;

  final bool _deleted;

  final void Function(int uid)? onTap;

  final bool enableServerRetry;

  final bool isBot;

  const VoceUserAvatar(
      {Key? key,
      required this.size,
      this.enableOnlineStatus = true,
      this.isCircle = useCircleAvatar,
      this.file,
      this.userInfoM,
      this.avatarBytes,
      this.name,
      this.enableServerRetry = false,
      required this.uid,
      this.backgroundColor = Colors.blue,
      this.onTap,
      this.isBot = false})
      : _deleted = (uid != null && uid > 0) ? false : true,
        super(key: key);

  const VoceUserAvatar.file(
      {Key? key,
      required String this.name,
      required int this.uid,
      required this.file,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableOnlineStatus = true,
      this.backgroundColor = Colors.blue,
      this.onTap,
      this.isBot = false})
      : avatarBytes = null,
        enableServerRetry = false,
        userInfoM = null,
        _deleted = uid <= 0,
        super(key: key);

  VoceUserAvatar.user(
      {Key? key,
      required UserInfoM this.userInfoM,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableOnlineStatus = true,
      this.backgroundColor = Colors.blue,
      this.onTap,
      this.enableServerRetry = true})
      : avatarBytes = null,
        name = userInfoM.userInfo.name,
        uid = userInfoM.uid,
        _deleted = false,
        file = null,
        isBot = userInfoM.userInfo.isBot ?? false,
        super(key: key);

  const VoceUserAvatar.name(
      {Key? key,
      required String this.name,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.uid,
      this.backgroundColor = Colors.blue,
      bool? enableOnlineStatus,
      this.onTap,
      this.enableServerRetry = true,
      this.isBot = false})
      : userInfoM = null,
        avatarBytes = null,
        enableOnlineStatus =
            enableOnlineStatus ?? false || (uid != null && uid > 0),
        _deleted = false,
        file = null,
        super(key: key);

  const VoceUserAvatar.deleted({
    Key? key,
    required this.size,
    this.isCircle = useCircleAvatar,
    this.backgroundColor = Colors.red,
  })  : userInfoM = null,
        enableServerRetry = false,
        avatarBytes = null,
        name = null,
        uid = null,
        enableOnlineStatus = false,
        _deleted = true,
        onTap = null,
        file = null,
        isBot = false,
        super(key: key);

  @override
  State<VoceUserAvatar> createState() => _VoceUserAvatarState();
}

class _VoceUserAvatarState extends State<VoceUserAvatar> {
  File? imageFile;
  // bool enableOnlineStatus = true;
  ValueNotifier<bool> enableOnlineStatus = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    App.app.chatService.subscribeUsers(_onUserChanged);
    App.app.chatService.subscribeChatServer(_onChatServerChanged);

    enableOnlineStatus.value = widget.enableOnlineStatus &&
        (App.app.chatServerM.properties.commonInfo?.showUserOnlineStatus ==
            true);

    _getImageFile();
  }

  @override
  void dispose() {
    App.app.chatService.unsubscribeUsers(_onUserChanged);
    App.app.chatService.unsubscribeChatServer(_onChatServerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._deleted) {
      return VoceAvatar.icon(
          // key: UniqueKey(),
          icon: CupertinoIcons.person,
          size: widget.size,
          isCircle: widget.isCircle,
          backgroundColor: widget.backgroundColor);
    } else {
      Widget rawAvatar;
      if (widget.file != null) {
        rawAvatar = VoceAvatar.file(
            file: widget.file!, size: widget.size, isCircle: widget.isCircle);
      } else if (widget.userInfoM != null &&
          widget.userInfoM!.userInfo.avatarUpdatedAt != 0 &&
          imageFile != null) {
        rawAvatar = VoceAvatar.file(
            file: imageFile!, size: widget.size, isCircle: widget.isCircle);
      } else {
        rawAvatar = _buildNonFileAvatar();
      }

      rawAvatar = Stack(
        alignment: Alignment.bottomRight,
        children: [
          rawAvatar,
          _buildBadge(),
        ],
      );
      if (widget.onTap != null && widget.uid != null) {
        rawAvatar = CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => widget.onTap!.call(widget.uid!),
            child: rawAvatar);
      }

      return rawAvatar;
    }
  }

  Widget _buildBadge() {
    final statusIndicatorSize = widget.size / 3;

    Widget badge = SizedBox.shrink();
    if (widget.enableOnlineStatus && widget.uid != null) {
      final onlineStatus = SharedFuncs.isSelf(widget.uid)
          ? ValueNotifier(true)
          : App.app.onlineStatusMap[widget.uid] ?? ValueNotifier(false);

      badge = ValueListenableBuilder<bool>(
          valueListenable: enableOnlineStatus,
          builder: (context, enabled, _) {
            if (enabled) {
              return ValueListenableBuilder<bool>(
                valueListenable: onlineStatus,
                builder: (context, isOnline, child) {
                  Color color;
                  if (isOnline) {
                    color = Color.fromRGBO(34, 197, 94, 1);
                  } else {
                    color = Color.fromRGBO(161, 161, 170, 1);
                  }
                  return Icon(Icons.circle,
                      size: statusIndicatorSize, color: color);
                },
              );
            } else {
              return SizedBox.shrink();
            }
          });
    } else if (widget.isBot) {
      badge = Image.asset('assets/images/bot.png',
          width: statusIndicatorSize, height: statusIndicatorSize);
    } else {
      return SizedBox.shrink();
    }

    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(statusIndicatorSize)),
          child: badge),
    );
  }

  Widget _buildNonFileAvatar() {
    if (widget.avatarBytes != null && widget.avatarBytes!.isNotEmpty) {
      return VoceAvatar.bytes(
          // key: UniqueKey(),
          avatarBytes: widget.avatarBytes!,
          size: widget.size,
          isCircle: widget.isCircle);
    } else if (widget.name != null && widget.name!.isNotEmpty) {
      return VoceAvatar.name(
          // key: UniqueKey(),
          name: widget.name!,
          size: widget.size,
          isCircle: widget.isCircle,
          fontColor: AppColors.grey200,
          backgroundColor: widget.backgroundColor);
    } else {
      return VoceAvatar.icon(
          // key: UniqueKey(),
          icon: AppIcons.contact,
          size: widget.size,
          isCircle: widget.isCircle,
          fontColor: AppColors.grey200,
          backgroundColor: widget.backgroundColor);
    }
  }

  Future<void> _getImageFile() async {
    if (widget.userInfoM != null &&
        widget.userInfoM!.userInfo.avatarUpdatedAt != 0) {
      imageFile = await UserAvatarHandler().readOrFetch(widget.userInfoM!,
          enableServerRetry: widget.enableServerRetry);

      if (imageFile != null && (await imageFile!.exists()) && mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _onUserChanged(
      UserInfoM userInfoM, EventActions action, bool afterReady) async {
    if (userInfoM.uid == widget.userInfoM?.uid &&
        userInfoM.userInfo.avatarUpdatedAt !=
            widget.userInfoM?.userInfo.avatarUpdatedAt) {
      _getImageFile();
    }
  }

  Future<void> _onChatServerChanged(ChatServerM chatServerM) async {
    enableOnlineStatus.value =
        chatServerM.properties.commonInfo?.showUserOnlineStatus == true;
  }
}
