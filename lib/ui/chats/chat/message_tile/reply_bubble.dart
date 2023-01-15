import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/user_avatar.dart';
import 'package:path/path.dart' as path;

class ReplyBubble extends StatelessWidget {
  /// The [ChatMsgM] being replied.
  final ChatMsgM repliedMsgM;

  /// The sender [UserInfoM] of the repliedMsgM.
  final UserInfoM repliedUser;
  final File? repliedImageFile;

  /// Current [ChatMsgM]
  final ChatMsgM msgM;

  late TextStyle _replyStyle;
  late TextStyle _replyMentionStyle;

  ReplyBubble(
      {required this.repliedMsgM,
      required this.repliedUser,
      this.repliedImageFile,
      required this.msgM}) {
    _replyStyle = TextStyle(
        fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.grey97);
    _replyMentionStyle = TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: AppColors.primaryHover);
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;

    switch (repliedMsgM.type) {
      case MsgDetailType.normal:
        switch (repliedMsgM.detailType) {
          case MsgContentType.text:
          case MsgContentType.markdown:
            final text = json.decode(repliedMsgM.detail)["content"] as String?;

            var children = <InlineSpan>[];

            text?.splitMapJoin(
              RegExp(r'\s@[0-9]+\s'),
              onMatch: (Match match) {
                final uidStr = match[0]?.substring(2);
                if (uidStr != null && uidStr.isNotEmpty) {
                  final uid = int.parse(uidStr);
                  children.add(WidgetSpan(
                      child: FutureBuilder<UserInfoM?>(
                    future: UserInfoDao().getUserByUid(uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final mentionStr = snapshot.data!.userInfo.name;
                        return Text(' @$mentionStr ',
                            style: _replyMentionStyle);
                      }
                      return Text(" @$uid ", style: _replyMentionStyle);
                    },
                  )));
                }
                return '';
              },
              onNonMatch: (String text) {
                children.add(TextSpan(text: text, style: _replyStyle));
                return '';
              },
            );

            content = RichText(
                text: TextSpan(style: _replyStyle, children: children));

            break;
          case MsgContentType.file:
            if (repliedMsgM.isImageMsg) {
              final tag = uuid();
              if (repliedImageFile != null) {
                content = Container(
                  constraints: BoxConstraints(maxHeight: 30, maxWidth: 50),
                  child: ImageBubble(
                      imageFile: repliedImageFile!,
                      localMid: tag,
                      getImage: () async {
                        final imageFile = await FileHandler.singleton
                            .getImageNormal(repliedMsgM);

                        if (imageFile != null) {
                          return imageFile;
                        }
                        return null;
                      }),
                );
              }
              break;
            } else {
              final String? filename =
                  repliedMsgM.msgNormal?.properties?["name"];
              if (filename != null && filename.isNotEmpty) {
                String basename, extension;
                try {
                  basename = path.basenameWithoutExtension(filename);
                  extension = path.extension(filename).substring(1);
                } catch (e) {
                  App.logger.severe(e);
                  basename = "file";
                  extension = "";
                }

                content = Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 3),
                      child: _buildFileIcon(extension),
                    ),
                    Flexible(
                      child: Text(
                        basename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.grey600),
                      ),
                    ),
                    Text("." + extension,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.grey600))
                  ],
                );
              }
            }
            break;
          case MsgContentType.archive:
            content = Text("An archive",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: AppColors.grey97));
            break;
          default:
            content = Text(json.decode(repliedMsgM.detail)["content"],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: AppColors.grey97));
        }
        break;
      case MsgDetailType.reply:
        content = Text(json.decode(repliedMsgM.detail)["content"],
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w500, color: AppColors.grey97));
        break;
      default:
        break;
    }

    Widget replied;

    bool hasMention = msgM.hasMention;

    if (content != null) {
      final name = repliedUser.userInfo.name.isNotEmpty
          ? repliedUser.userInfo.name
          : "Deleted User";
      replied = SizedBox(
        width: double.infinity,
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UserAvatar(
                  avatarSize: AvatarSize.s24,
                  uid: repliedUser.uid,
                  name: name,
                  avatarBytes: repliedUser.avatarBytes),
              Text(" $name  ",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.cyan500)),
            ],
          ),
          content
        ]),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: replied),
          TextBubble(
              content: msgM.msgReply?.content ?? "Unsupported content.",
              edited: msgM.edited == 1,
              hasMention: hasMention,
              maxLines: 10,
              enableShowMoreBtn: true)
        ],
      );
    } else {
      return TextBubble(
          content: msgM.msgReply?.content ?? "Unsupported content.",
          edited: msgM.edited == 1,
          hasMention: hasMention);
    }
  }

  Widget _buildFileIcon(String extension) {
    Widget svgPic;
    double width = 15;
    double height = 20;

    if (_isAudio(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_audio.svg",
          width: width, height: height);
    } else if (_isVideo(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_video.svg",
          width: width, height: height);
    } else if (extension.toLowerCase() == "pdf") {
      svgPic = SvgPicture.asset("assets/images/file_pdf.svg",
          width: width, height: height);
    } else if (extension.toLowerCase() == "text") {
      svgPic = SvgPicture.asset("assets/images/file_txt.svg",
          width: width, height: height);
    } else if (_isImage(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_image.svg",
          width: width, height: height);
    } else if (_isCode(extension)) {
      svgPic = SvgPicture.asset("assets/images/file_code.svg",
          width: width, height: height);
    } else {
      svgPic = SvgPicture.asset("assets/images/file.svg",
          width: width, height: height);
    }

    return svgPic;
  }

  bool _isAudio(String extension) {
    return audioExts.contains(extension.toLowerCase());
  }

  bool _isVideo(String extension) {
    return videoExts.contains(extension.toLowerCase());
  }

  bool _isImage(String extension) {
    return imageExts.contains(extension.toLowerCase());
  }

  bool _isCode(String extension) {
    return codeExts.contains(extension.toLowerCase());
  }
}
