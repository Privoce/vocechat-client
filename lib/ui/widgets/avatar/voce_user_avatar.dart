import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/file_handler/user_avatar_handler.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';

class VoceUserAvatar extends StatefulWidget {
  // General variables shared by all factories
  final double size;
  final bool isCircle;
  final bool enableOnlineStatus;
  final Color? backgroundColor;

  final UserInfoM? userInfoM;

  final File? file;

  final Uint8List? avatarBytes;

  final String? name;

  final int? uid;

  final bool _deleted;

  final void Function(int uid)? onTap;

  const VoceUserAvatar(
      {Key? key,
      required this.size,
      this.enableOnlineStatus = true,
      this.isCircle = useCircleAvatar,
      this.file,
      this.userInfoM,
      this.avatarBytes,
      this.name,
      required this.uid,
      this.backgroundColor = Colors.blue,
      this.onTap})
      : _deleted = (uid != null && uid > 0) ? false : true,
        super(key: key);

  VoceUserAvatar.file(
      {Key? key,
      required String this.name,
      required int this.uid,
      required File this.file,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableOnlineStatus = true,
      this.backgroundColor = Colors.blue,
      this.onTap})
      : avatarBytes = null,
        userInfoM = null,
        _deleted = false,
        super(key: key);

  VoceUserAvatar.user(
      {Key? key,
      required UserInfoM this.userInfoM,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableOnlineStatus = true,
      this.backgroundColor = Colors.blue,
      this.onTap})
      : avatarBytes = null,
        name = userInfoM.userInfo.name,
        uid = userInfoM.uid,
        _deleted = false,
        file = null,
        super(key: key);

  const VoceUserAvatar.name(
      {Key? key,
      required String this.name,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.uid,
      this.backgroundColor = Colors.blue,
      bool? enableOnlineStatus,
      this.onTap})
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
        avatarBytes = null,
        name = null,
        uid = null,
        enableOnlineStatus = false,
        _deleted = true,
        onTap = null,
        file = null,
        super(key: key);

  @override
  State<VoceUserAvatar> createState() => _VoceUserAvatarState();
}

class _VoceUserAvatarState extends State<VoceUserAvatar> {
  @override
  void initState() {
    super.initState();
    App.app.chatService.subscribeUsers(_onUserChanged);
  }

  @override
  void dispose() {
    App.app.chatService.unsubscribeUsers(_onUserChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._deleted) {
      return VoceAvatar.icon(
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
          widget.userInfoM!.userInfo.avatarUpdatedAt != 0) {
        rawAvatar = FutureBuilder<File?>(
            future: UserAvatarHander().readOrFetch(widget.userInfoM!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return VoceAvatar.file(
                    key: ValueKey("${snapshot.data!.lastModifiedSync()}"),
                    file: snapshot.data!,
                    size: widget.size,
                    isCircle: widget.isCircle);
              } else {
                return _buildNonFileAvatar();
              }
            });
      } else {
        rawAvatar = _buildNonFileAvatar();
      }

      // Add online status
      if (widget.enableOnlineStatus && widget.uid != null) {
        final onlineStatus = SharedFuncs.isSelf(widget.uid)
            ? ValueNotifier(true)
            : App.app.onlineStatusMap[widget.uid] ?? ValueNotifier(false);
        final statusIndicatorSize = widget.size / 3;

        rawAvatar = Stack(
          alignment: Alignment.bottomRight,
          children: [
            rawAvatar,
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(statusIndicatorSize)),
                child: ValueListenableBuilder<bool>(
                  valueListenable: onlineStatus,
                  builder: (context, isOnline, child) {
                    Color color;
                    if (isOnline || SharedFuncs.isSelf(widget.uid)) {
                      color = Color.fromRGBO(34, 197, 94, 1);
                    } else {
                      color = Color.fromRGBO(161, 161, 170, 1);
                    }
                    return Icon(Icons.circle,
                        size: statusIndicatorSize, color: color);
                  },
                ),
              ),
            ),
          ],
        );
      }

      if (widget.onTap != null && widget.uid != null) {
        rawAvatar = CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => widget.onTap!(widget.uid!),
            child: rawAvatar);
      }

      return rawAvatar;
    }
  }

  Widget _buildNonFileAvatar() {
    if (widget.avatarBytes != null && widget.avatarBytes!.isNotEmpty) {
      return VoceAvatar.bytes(
          avatarBytes: widget.avatarBytes!,
          size: widget.size,
          isCircle: widget.isCircle);
    } else if (widget.name != null && widget.name!.isNotEmpty) {
      return VoceAvatar.name(
          name: widget.name!,
          size: widget.size,
          isCircle: widget.isCircle,
          fontColor: AppColors.grey200,
          backgroundColor: widget.backgroundColor);
    } else {
      return VoceAvatar.icon(
          icon: AppIcons.contact,
          size: widget.size,
          isCircle: widget.isCircle,
          fontColor: AppColors.grey200,
          backgroundColor: widget.backgroundColor);
    }
  }

  Future<void> _onUserChanged(UserInfoM userInfoM, EventActions action) async {
    if (userInfoM.uid == widget.userInfoM?.uid) {
      setState(() {});
    }
  }
}
