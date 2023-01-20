import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/input_field/app_mentions.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/archive_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/file_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/chat_image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/markdown_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/msg_tile_frame.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/reply_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/text_bubble.dart';
import 'package:vocechat_client/ui/widgets/avatar/avatar_size.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum ImageType { thumb, original }

class MessageTile extends StatefulWidget {
  final bool isFollowing;
  final ChatMsgM chatMsgM;
  final UserInfoM userInfoM;
  final ChatMsgM? repliedMsgM;
  final UserInfoM? repliedUserInfoM;
  final File? repliedImageFile;
  final bool enableAvatarMention;
  final GlobalKey<AppMentionsState>? mentionsKey;
  final bool enableShowMoreBtn;

  // final bool selectNotifier;
  final ValueNotifier<List<ChatMsgM>> selectNotifier;
  final ValueNotifier<bool> isSelecting;
  final Function(bool) onChanged;

  // content
  final File? image;
  final ImageType? imageType;
  final Archive? archive;
  final int pinnedBy;
  final void Function(ChatMsgM old, String reaction) onSendReaction;

  final double avatarSize;

  MessageTile(
      {Key? key,
      // required this.shouldShowAvatar,
      required this.isFollowing,
      required this.chatMsgM,
      required this.userInfoM,
      required this.isSelecting,
      required this.selectNotifier,
      required this.onChanged,
      required this.pinnedBy,
      this.repliedMsgM,
      this.repliedUserInfoM,
      this.repliedImageFile,
      this.enableAvatarMention = false,
      this.mentionsKey,
      this.enableShowMoreBtn = false,
      this.image,
      this.imageType,
      this.archive,
      required this.onSendReaction,
      this.avatarSize = AvatarSize.s48})
      : super(key: key);

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  late bool selected;

  // Auto-deletion variables.
  final ValueNotifier<int> _autoDeletionCountDown = ValueNotifier(0);
  Timer? _autoDeletionTimer;
  bool _isTimerOn = false;

  @override
  void initState() {
    super.initState();

    selected = widget.selectNotifier.value
        .map((e) => e.mid)
        .contains(widget.chatMsgM.mid);

    initTimer(widget.chatMsgM);
  }

  @override
  void dispose() {
    _autoDeletionTimer?.cancel();
    super.dispose();
  }

  void initTimer(ChatMsgM chatMsgM) {
    if (_isAutoDeletionMsg(chatMsgM)) {
      _autoDeletionTimer?.cancel();
      _autoDeletionCountDown.value = _getAutoDeletionRemains(chatMsgM);
      if (_autoDeletionCountDown.value > 0) {
        if (!_isTimerOn) {
          _isTimerOn = true;
          _autoDeletionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
            _autoDeletionCountDown.value -= 1000;
            if (_autoDeletionCountDown.value <= 0) {
              ChatMsgDao().deleteMsgByLocalMid(chatMsgM).then((value) async {
                FileHandler.singleton.deleteWithChatMsgM(chatMsgM);
                App.app.chatService
                    .fireReaction(ReactionTypes.delete, chatMsgM.mid);

                if (chatMsgM.isGroupMsg) {
                  final curMaxMid =
                      await ChatMsgDao().getChannelMaxMid(chatMsgM.gid);
                  if (curMaxMid > -1) {
                    final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

                    if (msg != null) {
                      App.app.chatService.fireSnippet(msg);
                    }
                  }
                } else {
                  final curMaxMid =
                      await ChatMsgDao().getDmMaxMid(chatMsgM.dmUid);
                  if (curMaxMid > -1) {
                    final msg = await ChatMsgDao().getMsgByMid(curMaxMid);

                    if (msg != null) {
                      App.app.chatService.fireSnippet(msg);
                    }
                  }
                }
              });
              _autoDeletionTimer?.cancel();
            }
          });
        }
      }
    }
  }

  bool _isAutoDeletionMsg(ChatMsgM chatMsgM) {
    final isMsgNormalAutoDeletion = chatMsgM.msgNormal?.expiresIn != null &&
        chatMsgM.msgNormal?.expiresIn != 0;

    return isMsgNormalAutoDeletion;
  }

  int _getAutoDeletionRemains(ChatMsgM chatMsgM) {
    if (_isAutoDeletionMsg(chatMsgM)) {
      final expiresIn = chatMsgM.msgNormal?.expiresIn;
      if (expiresIn != null && expiresIn > 0) {
        final currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
        final msgTimeStamp = chatMsgM.createdAt;

        final dif = msgTimeStamp + expiresIn * 1000 - currentTimeStamp;
        if (dif < 0) {
          // return expiresIn * 1000;
          return 0;
        } else {
          // return min(dif, expiresIn * 1000);
          return dif;
        }
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    if (_isAutoDeletionMsg(widget.chatMsgM) &&
        _autoDeletionCountDown.value <= 0) {
      return SizedBox.shrink();
    }

    // left padding + avatar      + gap + right padding + status
    // 16           + avatarSize  + 8   + 16            + 50
    double contentWidth =
        (MediaQuery.of(context).orientation == Orientation.portrait
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.height) -
            90 -
            widget.avatarSize;

    if (widget.isSelecting.value) contentWidth -= 30;
    Widget child = Container(
        constraints: widget.isFollowing
            ? BoxConstraints(minHeight: 20)
            : BoxConstraints(minHeight: 40),
        padding: widget.isFollowing
            ? EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        margin: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isSelecting.value) _buildSelect(context, 30.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.pinnedBy != 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 50, bottom: 4),
                    child: FutureBuilder<UserInfoM?>(
                        future: UserInfoDao().getUserByUid(widget.pinnedBy),
                        builder: (context, snapshot) {
                          final locale = Localizations.localeOf(context);
                          String pinStr;
                          if (locale == Locale("zh")) {
                            pinStr = "被";
                            if (snapshot.hasData && snapshot.data != null) {
                              pinStr += " ${snapshot.data!.userInfo.name} ";
                            }
                            pinStr += "钉选";
                          } else {
                            pinStr = "pinned";
                            if (snapshot.hasData && snapshot.data != null) {
                              pinStr += " by ${snapshot.data!.userInfo.name}";
                            }
                          }
                          return SizedBox(
                            width: contentWidth,
                            child: Row(
                              children: [
                                Icon(AppIcons.pin,
                                    size: 12, color: AppColors.grey400),
                                SizedBox(width: 4),
                                Text(pinStr,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.grey400)),
                              ],
                            ),
                          );
                        }),
                  ),
                MsgTileFrame(
                  username: widget.userInfoM.userInfo.name,
                  uid: widget.userInfoM.uid,
                  avatarBytes: widget.userInfoM.avatarBytes,
                  avatarSize: widget.avatarSize,
                  enableOnlineStatus: false,
                  enableAvatarMention: widget.enableAvatarMention,
                  enableUserDetailPush: true,
                  mentionsKey: widget.mentionsKey,
                  timeStamp: widget.chatMsgM.createdAt,
                  contentWidth: contentWidth,
                  child: _buildContents(contentWidth, context),
                ),
              ],
            )
          ],
        ));
    if (widget.isSelecting.value) {
      return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: (() {
            setState(() {
              selected = !selected;
              widget.onChanged(selected);
            });
          }),
          child: IgnorePointer(ignoring: true, child: child));
    } else {
      return child;
    }
  }

  Widget _buildContents(double contentWidth, BuildContext context) {
    try {
      return Column(
        children: [
          Container(
              constraints: BoxConstraints(minHeight: 20),
              width: contentWidth,
              child: _buildContentBubble(context)),
          if (widget.chatMsgM.reactions.isNotEmpty)
            Container(
              constraints: BoxConstraints(minHeight: 20),
              width: contentWidth,
              child: _buildReactions(context),
            ),
          if (_autoDeletionCountDown.value > 0)
            _buildAutoDeletionCountDown(context, contentWidth)
        ],
      );
    } catch (e) {
      App.logger.severe(e);
      return TextBubble(
          content: "Unsupported Message Type",
          hasMention: false,
          enableCopy: false,
          enableOg: false,
          enableShowMoreBtn: false);
    }
  }

  Widget _buildSelect(BuildContext context, double size) {
    // bool selected
    return SizedBox(
      height: size,
      width: size,
      child: ValueListenableBuilder<List<ChatMsgM>>(
          valueListenable: widget.selectNotifier,
          builder: (context, selectedMsgM, _) {
            bool selected = selectedMsgM.indexWhere((element) =>
                    element.localMid == widget.chatMsgM.localMid) !=
                -1;
            return Center(
              child: selected
                  ? Icon(AppIcons.select, color: Colors.cyan, size: 30)
                  : SizedBox(width: 30),
            );
          }),
    );
  }

  Widget _buildContentBubble(BuildContext context) {
    switch (widget.chatMsgM.type) {
      case MsgDetailType.normal:
        switch (widget.chatMsgM.detailType) {
          case MsgContentType.text:
            final m = widget.chatMsgM;
            String? content = "";
            bool hasMention = widget.chatMsgM.hasMention;
            switch (m.type) {
              case MsgDetailType.normal:
                content = m.msgNormal?.content;
                break;
              case MsgDetailType.reply:
                content = m.msgReply?.content;
                break;
              default:
            }

            return TextBubble(
                content: content ?? AppLocalizations.of(context)!.noContent,
                edited: m.edited == 1,
                hasMention: hasMention,
                chatMsgM: widget.chatMsgM,
                maxLines: 16,
                enableShowMoreBtn: true);

          case MsgContentType.markdown:
            return MarkdownBubble(
                markdownText: widget.chatMsgM.msgNormal?.content ??
                    AppLocalizations.of(context)!.noContent,
                edited: widget.chatMsgM.edited == 1);

          case MsgContentType.file:
            if (widget.chatMsgM.isImageMsg) {
              return ChatImageBubble(
                  imageFile: widget.image,
                  chatMsgM: widget.chatMsgM,
                  getImage: () async {
                    final imageFile = await FileHandler.singleton
                        .getImageNormal(widget.chatMsgM);

                    if (imageFile != null) {
                      return imageFile;
                    }
                    return null;
                  });
              // return ImageBubbleTest(chatMsgM: widget.chatMsgM);
            }
            // else if (widget.chatMsgM.isVideoMsg) {
            //   return VideoBubble(
            //     chatMsgM: widget.chatMsgM,
            //     getVideoFile: (_) async {
            //       return null;
            //     },
            //   );
            // }
            else {
              final msgNormal = widget.chatMsgM.msgNormal!;
              final name = msgNormal.properties?["name"] ?? "";
              final size = msgNormal.properties?["size"] ?? 0;
              return FileBubble(
                  filePath: msgNormal.content,
                  name: name,
                  size: size,
                  getLocalFile: () async {
                    return FileHandler.singleton.getLocalFile(widget.chatMsgM);
                  },
                  getFile: (onProgress) async {
                    return FileHandler.singleton
                        .getFile(widget.chatMsgM, onProgress);
                  },
                  chatMsgM: widget.chatMsgM);
            }
          case MsgContentType.archive:
            return ArchiveBubble(
                archive: widget.archive,
                archiveId: widget.chatMsgM.msgNormal!.content,
                isSelecting: widget.isSelecting.value,
                lengthLimit: 3,
                getFile: FileHandler.singleton.getArchiveFile);
          default:
        }
        break;
      case MsgDetailType.reply:
        if (widget.repliedMsgM != null && widget.repliedUserInfoM != null) {
          return ReplyBubble(
              repliedMsgM: widget.repliedMsgM!,
              repliedUser: widget.repliedUserInfoM!,
              repliedImageFile: widget.repliedImageFile,
              msgM: widget.chatMsgM);
        }
        break;
      default:
    }
    return TextBubble(
        content: "Unsupported Message Type",
        hasMention: false,
        enableShowMoreBtn: false);
  }

  Widget _buildAutoDeletionCountDown(
      BuildContext context, double contentWidth) {
    return ValueListenableBuilder<int>(
        valueListenable: _autoDeletionCountDown,
        builder: (context, countDown, _) {
          return SizedBox(
            height: 20,
            width: contentWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.grey400),
                SizedBox(width: 4),
                SizedBox(
                  child: Text(
                    _printDuration(Duration(milliseconds: countDown)),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: AppColors.grey400,
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    // Days
    if (duration.inDays > 1) {
      final remains = duration - Duration(days: duration.inDays);
      if (remains.inHours > 12) {
        return (duration.inDays + 1).toString() +
            AppLocalizations.of(context)!.days;
      } else {
        return duration.inDays.toString() + AppLocalizations.of(context)!.days;
      }
    } else if (duration.inDays > 0) {
      final remains = duration - Duration(days: duration.inDays);
      if (remains.inHours > 12) {
        return "2" + AppLocalizations.of(context)!.days;
      } else {
        return "1" + AppLocalizations.of(context)!.day;
      }
    }

    // Hours
    else if (duration.inHours > 1) {
      final remains = duration - Duration(hours: duration.inHours);
      if (remains.inMinutes > 30) {
        return (duration.inHours + 1).toString() +
            AppLocalizations.of(context)!.hours;
      } else {
        return duration.inHours.toString() +
            AppLocalizations.of(context)!.hours;
      }
    } else if (duration.inHours > 0) {
      final remains = duration - Duration(hours: duration.inHours);
      if (remains.inMinutes > 30) {
        return "2" + AppLocalizations.of(context)!.hours;
      } else {
        return "1" + AppLocalizations.of(context)!.hour;
      }
    }

    // Minutes
    else if (duration.inMinutes > 1) {
      final remains = duration - Duration(minutes: duration.inMinutes);
      if (remains.inSeconds > 30) {
        return (duration.inMinutes + 1).toString() +
            AppLocalizations.of(context)!.minutes;
      } else {
        return duration.inMinutes.toString() +
            AppLocalizations.of(context)!.minutes;
      }
    } else if (duration.inMinutes > 0) {
      return "1" + AppLocalizations.of(context)!.minute;
    }

    // Last minute
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return twoDigitSeconds;
  }

  bool _isLink(String input) {
    final matcher = RegExp(
        r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)");
    return matcher.hasMatch(input);
  }

  String getFileSizeString(int bytes) {
    const suffixes = ["b", "kb", "mb", "gb", "tb"];
    var i = (log(bytes) / log(1000)).floor();
    return ((bytes / pow(1000, i)).toStringAsFixed(1)) +
        suffixes[i].toUpperCase();
  }

  Widget _buildReactions(BuildContext context) {
    var map = <String, ReactionItem>{}; // emoji: quantity

    for (var element in widget.chatMsgM.reactions) {
      if (!map.containsKey(element.reaction)) {
        map[element.reaction] = ReactionItem(frequency: 1);
      } else {
        map.update(element.reaction, (value) {
          return ReactionItem(frequency: value.frequency + 1);
        });
      }

      if (element.fromUid == App.app.userDb?.uid) {
        map[element.reaction]?.isSelfReact = true;
      }
    }

    return Wrap(
        children: List<Widget>.generate(map.length, (index) {
      final reaction = map.keys.toList()[index];
      final int quantity = map[reaction]?.frequency ?? 1;
      final bool isSelf = map[reaction]?.isSelfReact ?? false;
      return Padding(
        padding: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
        child: _buildReactionTile(reaction, quantity, isSelf),
      );
    }));
  }

  Widget _buildReactionTile(String reaction, int quantity, bool isSelf) {
    return GestureDetector(
      onTap: () {
        widget.onSendReaction(widget.chatMsgM, reaction);
      },
      child: Container(
          height: 24,
          width: 42,
          decoration: BoxDecoration(
              border: Border.all(
                  color: isSelf ? AppColors.cyan500 : AppColors.cyan100),
              color: isSelf ? AppColors.cyan200 : AppColors.cyan100,
              borderRadius: BorderRadius.circular(6)),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.cyan500),
                children: [
                  TextSpan(text: reaction),
                  TextSpan(text: " $quantity"),
                ]),
          )),
    );
  }
}

class ReactionItem {
  int frequency = 1;
  bool isSelfReact = false;

  ReactionItem({int frequency = 1, this.isSelfReact = false}) {
    if (frequency < 0) {
      this.frequency = 0;
    } else {
      this.frequency = frequency;
    }
  }
}
