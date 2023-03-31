import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';

class VoceAvatar extends StatelessWidget {
  // General variables
  final Uint8List? avatarBytes;
  final String? name;
  final IconData? icon;
  final double size;

  // For circle avatar
  final bool isCircle;

  // For rectangle avatar
  // BorderRadius? borderRadius;
  final double _radiusFactor = 0.1;

  VoceAvatar.bytes(
      {Key? key,
      required Uint8List this.avatarBytes,
      this.size = VoceAvatarSize.s36,
      this.isCircle = true})
      : name = null,
        icon = null,
        super(key: key);

  const VoceAvatar.name(
      {Key? key,
      required String this.name,
      this.size = VoceAvatarSize.s36,
      this.isCircle = true})
      : avatarBytes = null,
        icon = null,
        super(key: key);

  const VoceAvatar.icon(
      {Key? key,
      required IconData this.icon,
      this.size = VoceAvatarSize.s36,
      this.isCircle = true})
      : avatarBytes = null,
        name = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCircle) {
      if (avatarBytes != null && avatarBytes!.isNotEmpty) {
        return Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                image: DecorationImage(
                    fit: BoxFit.cover, image: MemoryImage(avatarBytes!))));
      } else if (name != null && name!.isNotEmpty) {
        final initials = SharedFuncs.getInitials(name!);
        double fontSize = initials.length > 3 ? size / 3.5 : size / 2.5;

        return SizedBox(
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
      } else if (icon != null) {
        double iconSize = size / 2;
        return SizedBox(
            height: size,
            width: size,
            child: CircleAvatar(
                backgroundColor: AppColors.grey200,
                child: Icon(icon, size: iconSize, color: AppColors.grey500)));
      } else {
        double iconSize = size / 2;
        return SizedBox(
            height: size,
            width: size,
            child: CircleAvatar(
                backgroundColor: AppColors.grey200,
                child: Icon(CupertinoIcons.person,
                    size: iconSize, color: AppColors.grey500)));
      }
    } else {
      if (avatarBytes != null && avatarBytes!.isNotEmpty) {
        final borderRadius = BorderRadius.circular(size * _radiusFactor);
        return ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
              height: size,
              width: size,
              child: Image.memory(avatarBytes!, fit: BoxFit.cover)),
        );
      } else if (name != null && name!.isNotEmpty) {
        final initials = SharedFuncs.getInitials(name!);
        double fontSize = initials.length > 3 ? size / 3.5 : size / 2.5;
        final borderRadius = BorderRadius.circular(size * _radiusFactor);

        return ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(color: AppColors.grey200),
            child: Center(
              child: Text(
                initials,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(color: AppColors.grey600, fontSize: fontSize),
              ),
            ),
          ),
        );
      } else if (icon != null) {
        double iconSize = size / 2;
        final borderRadius = BorderRadius.circular(size * _radiusFactor);

        return ClipRRect(
          borderRadius: borderRadius,
          child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: AppColors.grey200),
              child: Center(
                  child: Icon(icon, size: iconSize, color: AppColors.grey500))),
        );
      } else {
        double iconSize = size / 2;
        final borderRadius = BorderRadius.circular(size * _radiusFactor);

        return ClipRRect(
          borderRadius: borderRadius,
          child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: AppColors.grey200),
              child: Center(
                  child: Icon(CupertinoIcons.person,
                      size: iconSize, color: AppColors.grey500))),
        );
      }
    }
  }
}
