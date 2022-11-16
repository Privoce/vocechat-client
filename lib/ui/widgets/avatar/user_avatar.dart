import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/ui/app_colors.dart';

class UserAvatar extends StatefulWidget {
  final String name;
  final double avatarSize;

  /// If uid is set to null, it will not response to tap gesture, hence app not
  /// be pushed to ContactDetailPage.
  final int? uid;
  final bool isSelf;
  final Uint8List? avatarBytes;
  final bool enableOnlineStatus;
  final Color bgColor;

  const UserAvatar(
      {Key? key,
      required this.avatarSize,
      this.isSelf = false,
      this.uid,
      required this.name,
      required this.avatarBytes,
      this.enableOnlineStatus = false})
      : bgColor = Colors.blue,
        super(key: key);

  UserAvatar.deletedUser({
    Key? key,
    required this.avatarSize,
  })  : name = "Deleted User",
        avatarBytes = null,
        enableOnlineStatus = false,
        uid = -1,
        isSelf = false,
        bgColor = AppColors.systemRed,
        super(key: key);

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  ValueNotifier<bool> onlineStatus = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    if (widget.enableOnlineStatus) {
      onlineStatus.value = App.app.isSelf(widget.uid)
          ? true
          : App.app.onlineStatusMap[widget.uid] ?? false;

      App.app.chatService.subscribeUserStatus(_onUserStatus);
    }
  }

  @override
  void dispose() {
    super.dispose();

    if (widget.enableOnlineStatus) {
      App.app.chatService.unsubscribeUserStatus(_onUserStatus);
    }
  }

  Future<void> _onUserStatus(int uid, bool isOnline, bool afterReady) async {
    if (uid != widget.uid) {
      return;
    }
    onlineStatus.value = isOnline;
  }

  @override
  Widget build(BuildContext context) {
    onlineStatus.value = onlineStatus.value = App.app.isSelf(widget.uid)
        ? true
        : App.app.onlineStatusMap[widget.uid] ?? false;

    double statusIndicatorSize = widget.avatarSize / 3;
    late double fontSize;

    Widget avatar;

    if (widget.avatarBytes?.isNotEmpty ?? false) {
      avatar = Container(
          height: widget.avatarSize,
          width: widget.avatarSize,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                  fit: BoxFit.cover, image: MemoryImage(widget.avatarBytes!))));
    } else {
      final initials = getInitials(widget.name);

      if (initials.length > 3) {
        fontSize = widget.avatarSize / 3.5;
      } else {
        fontSize = widget.avatarSize / 2.5;
      }
      avatar = SizedBox(
          height: widget.avatarSize,
          width: widget.avatarSize,
          child: CircleAvatar(
              backgroundColor: widget.bgColor,
              child: Text(
                initials,
                style: TextStyle(color: AppColors.grey200, fontSize: fontSize),
              )));
    }

    return SizedBox(
      width: widget.avatarSize,
      height: widget.avatarSize,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          if (widget.enableOnlineStatus &&
              widget.uid != null &&
              widget.uid! > -1)
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
                    if (isOnline || widget.isSelf) {
                      color = Color.fromRGBO(34, 197, 94, 1);
                    } else {
                      color = Color.fromRGBO(161, 161, 170, 1);
                    }
                    return Icon(Icons.circle,
                        size: statusIndicatorSize, color: color);
                  },
                ),
              ),
            )
        ],
      ),
    );
  }
}
