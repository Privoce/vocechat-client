import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';

class VoceAvatar extends StatelessWidget {
  final Uint8List avatarBytes;
  final String name;
  final double size;
  final double? cornerRadius;

  const VoceAvatar.circle(
      {Key? key,
      required this.avatarBytes,
      required this.name,
      this.size = VoceAvatarSize.s36})
      : cornerRadius = null,
        super(key: key);

  const VoceAvatar.rect(
      {Key? key,
      required this.avatarBytes,
      required this.name,
      this.size = VoceAvatarSize.s36,
      this.cornerRadius = 8})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (avatarBytes.isNotEmpty) {
      avatar = Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      fit: BoxFit.cover, image: MemoryImage(avatarBytes)))),
        ],
      );
    } else if (name.isNotEmpty) {
      final initials = SharedFuncs.getInitials(name);
      double fontSize;
      if (initials.length > 3) {
        fontSize = size / 3.5;
      } else {
        fontSize = size / 2.5;
      }
      avatar = SizedBox(
          height: size,
          width: size,
          child: CircleAvatar(
              backgroundColor: AppColors.grey200,
              child: Center(
                child: Text(
                  initials,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style:
                      TextStyle(color: AppColors.grey600, fontSize: fontSize),
                ),
              )));
    } else {
      avatar =
          Icon(CupertinoIcons.person, size: size / 2, color: AppColors.grey500);
    }

    return avatar;
  }
}
