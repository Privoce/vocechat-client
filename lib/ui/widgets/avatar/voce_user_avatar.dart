import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';

class VoceUserAvatar extends StatelessWidget {
  // General variables shared by all factories
  final double size;
  final bool isCircle;
  final bool enableOnlineStatus;

  final UserInfoM? userInfoM;

  final Uint8List? avatarBytes;

  final String? name;

  final int? _uid;

  final bool _deleted;

  // VoceUserAvatar.bytes(
  //     {required this.avatarBytes,
  //     required this.size,
  //     this.isCircle = useCircleAvatar,
  //     this.enableOnlineStatus = true}):userInfoM = null,
  //     _uid
  //     ;

  VoceUserAvatar.user(
      {required UserInfoM this.userInfoM,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableOnlineStatus = true})
      : avatarBytes = userInfoM.avatarBytes,
        name = userInfoM.userInfo.name,
        _uid = userInfoM.uid,
        _deleted = false;

  VoceUserAvatar.name(
      {required String this.name,
      required this.size,
      this.isCircle = useCircleAvatar})
      : userInfoM = null,
        avatarBytes = null,
        _uid = null,
        enableOnlineStatus = false,
        _deleted = false;

  VoceUserAvatar.deleted({required this.size, this.isCircle = useCircleAvatar})
      : userInfoM = null,
        avatarBytes = null,
        name = null,
        _uid = null,
        enableOnlineStatus = false,
        _deleted = true;

  @override
  Widget build(BuildContext context) {
    if (_deleted) {
      return VoceAvatar.icon(
          icon: CupertinoIcons.person,
          size: size,
          isCircle: isCircle,
          backgroundColor: Colors.red);
    } else {
      Widget rawAvatar;
      if (userInfoM != null && userInfoM!.avatarBytes.isNotEmpty) {
        rawAvatar = VoceAvatar.bytes(
            avatarBytes: avatarBytes!, size: size, isCircle: isCircle);
      } else if (name != null && name!.isNotEmpty) {
        rawAvatar =
            VoceAvatar.name(name: name!, size: size, isCircle: isCircle);
      } else {
        rawAvatar = VoceAvatar.icon(
            icon: AppIcons.contact, size: size, isCircle: isCircle);
      }

      // Add online status
      if (enableOnlineStatus &&
          _uid != null &&
          App.app.onlineStatusMap.containsKey(_uid)) {
        final onlineStatus = App.app.onlineStatusMap[_uid]!;
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
                    if (isOnline || SharedFuncs.isSelf(_uid)) {
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

      return rawAvatar;
    }
  }
}
