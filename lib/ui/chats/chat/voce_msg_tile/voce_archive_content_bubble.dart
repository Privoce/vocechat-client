import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive_msg.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive_user.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/helpers/time_helper.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';

class VoceArchiveContentBubble extends StatefulWidget {
  final ArchiveMsg archiveMsg;
  final String archiveId;
  final ArchiveUser archiveUser;
  final Future<File?> Function(String, int, String) getFile;

  VoceArchiveContentBubble(
      {Key? key,
      required this.archiveMsg,
      required this.archiveId,
      required this.archiveUser,
      required this.getFile})
      : super(key: key);

  @override
  State<VoceArchiveContentBubble> createState() =>
      _VoceArchiveContentBubbleState();
}

class _VoceArchiveContentBubbleState extends State<VoceArchiveContentBubble> {
  File? avatarFile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(context),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: _buildContent(),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (widget.archiveUser.avatar != null) {
      return FutureBuilder<File?>(
        future: widget.getFile(widget.archiveId, widget.archiveUser.avatar!,
            widget.archiveMsg.fileName),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return VoceAvatar.file(
                file: snapshot.data!, size: VoceAvatarSize.s18);
          }
          return VoceUserAvatar.name(
              name: widget.archiveUser.name,
              backgroundColor: Colors.blue,
              size: VoceAvatarSize.s18);
        },
      );
    } else {
      return VoceAvatar.name(
          name: widget.archiveUser.name,
          backgroundColor: Colors.blue,
          size: VoceAvatarSize.s18);
    }
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(widget.archiveUser.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF344054))),
        ),
        const SizedBox(width: 8),
        Text(
          " ${widget.archiveMsg.createdAt.toChatTime24StrEn(context)}",
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xFFBFBFBF)),
        )
      ],
    );
  }

  Widget _buildContent() {
    // TODO: update error message widget.
    String errorMsg = "Unsupported type.";
    switch (widget.archiveMsg.contentType) {
      case typeText:
        return Text(widget.archiveMsg.content ?? "No content",
            style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF344054)));
      case typeMarkdown:
        return Text(widget.archiveMsg.content ?? "No content",
            style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF344054)));
      case typeFile:
        if (widget.archiveMsg.isImageMsg) {
          if (widget.archiveMsg.thumbnailId != null) {
            return FutureBuilder<File?>(
                future: widget.getFile(widget.archiveId,
                    widget.archiveMsg.thumbnailId!, widget.archiveMsg.fileName),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.file(snapshot.data!);
                  }
                  return const SizedBox();
                });
          } else {
            return const SizedBox();
          }
        } else {
          return const SizedBox();
        }
      default:
        return Text(errorMsg,
            style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF344054)));
    }
  }
}
