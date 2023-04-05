import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';

class VoceUserAvatar extends StatelessWidget {
  // General variables shared by all factories
  final double size;
  final bool isCircle;
  final bool enableOnlineStatus;
  final Color? backgroundColor;

  final UserInfoM? userInfoM;

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
      this.userInfoM,
      this.avatarBytes,
      this.name,
      required this.uid,
      this.backgroundColor = Colors.blue,
      this.onTap})
      : _deleted = (uid != null && uid > 0) ? false : true,
        super(key: key);

  VoceUserAvatar.user(
      {Key? key,
      required UserInfoM this.userInfoM,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableOnlineStatus = true,
      this.backgroundColor = Colors.blue,
      this.onTap})
      : avatarBytes = userInfoM.avatarBytes,
        name = userInfoM.userInfo.name,
        uid = userInfoM.uid,
        _deleted = false,
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
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_deleted) {
      return VoceAvatar.icon(
          icon: CupertinoIcons.person,
          size: size,
          isCircle: isCircle,
          backgroundColor: backgroundColor);
    } else {
      Widget rawAvatar;
      if (userInfoM != null && userInfoM!.avatarBytes.isNotEmpty) {
        rawAvatar = VoceAvatar.bytes(
            avatarBytes: avatarBytes!, size: size, isCircle: isCircle);
      } else if (avatarBytes != null && avatarBytes!.isNotEmpty) {
        rawAvatar = VoceAvatar.bytes(
            avatarBytes: avatarBytes!, size: size, isCircle: isCircle);
      } else if (name != null && name!.isNotEmpty) {
        rawAvatar = VoceAvatar.name(
            name: name!,
            size: size,
            isCircle: isCircle,
            fontColor: AppColors.grey200,
            backgroundColor: backgroundColor);
      } else {
        rawAvatar = VoceAvatar.icon(
            icon: AppIcons.contact,
            size: size,
            isCircle: isCircle,
            fontColor: AppColors.grey200,
            backgroundColor: backgroundColor);
      }

      // Add online status
      if (enableOnlineStatus && uid != null) {
        final onlineStatus = SharedFuncs.isSelf(uid)
            ? ValueNotifier(true)
            : App.app.onlineStatusMap[uid] ?? ValueNotifier(false);
        final statusIndicatorSize = size / 3;

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
                    if (isOnline || SharedFuncs.isSelf(uid)) {
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

      if (onTap != null && uid != null) {
        rawAvatar = CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => onTap!(uid!),
            child: rawAvatar);
      }

      return rawAvatar;
    }
  }
}
