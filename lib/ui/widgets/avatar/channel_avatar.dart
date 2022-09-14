import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';

class ChannelAvatar extends StatefulWidget {
  /// All channels are private by default.
  final bool isPublic;
  final double avatarSize;
  final Uint8List avatarBytes;
  final String? name;

  late final double iconSize;
  late double fontSize;

  ChannelAvatar(
      {Key? key,
      required this.avatarSize,
      this.isPublic = false,
      required this.avatarBytes,
      this.name})
      : super(key: key) {
    iconSize = avatarSize / 2;
  }

  @override
  State<ChannelAvatar> createState() => _ChannelAvatarState();
}

class _ChannelAvatarState extends State<ChannelAvatar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (widget.avatarBytes.isNotEmpty) {
      avatar = Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
              height: widget.avatarSize,
              width: widget.avatarSize,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: MemoryImage(widget.avatarBytes)))),
        ],
      );
    } else if (widget.name != null && widget.name!.isNotEmpty) {
      final initials = getInitials(widget.name!);
      if (initials.length > 3) {
        widget.fontSize = widget.avatarSize / 3.5;
      } else {
        widget.fontSize = widget.avatarSize / 2.5;
      }
      avatar = SizedBox(
          height: widget.avatarSize,
          width: widget.avatarSize,
          child: CircleAvatar(
              backgroundColor: AppColors.grey200,
              child: Center(
                child: Text(
                  initials,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                      color: AppColors.grey600, fontSize: widget.fontSize),
                ),
              )));
    } else {
      avatar = widget.isPublic
          ? Icon(AppIcons.channel,
              size: widget.iconSize, color: AppColors.grey500)
          : Icon(AppIcons.private_channel,
              size: widget.iconSize, color: AppColors.grey500);
    }

    return avatar;
  }
}
