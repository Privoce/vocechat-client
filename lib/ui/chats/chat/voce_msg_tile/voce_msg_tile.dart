import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/globals.dart';
import 'package:vocechat_client/helpers/time_helper.dart';
import 'package:vocechat_client/models/ui_models/msg_tile_data.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/file_handler/audio_file_handler.dart';
import 'package:vocechat_client/services/send_task_queue/send_task_queue.dart';
import 'package:vocechat_client/services/voce_send_service.dart';
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/chats/chat/message_tile/image_bubble/tile_image_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/voce_reply_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/voce_archive_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/audio/voce_audio_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/voce_file_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/voce_markdown_bubble.dart';
import 'package:vocechat_client/ui/chats/chat/voce_msg_tile/voce_text_bubble.dart';
import 'package:vocechat_client/ui/contact/contact_detail_page.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VoceMsgTile extends StatefulWidget {
  final MsgTileData tileData;
  final Animation<double> sizeFactor;

  // Selection
  final ValueNotifier<bool>? enableSelection;
  final void Function(MsgTileData tileData, bool selected)? onSelectChange;

  // late final bool isSelf;
  late final bool selfRightLayout;

  VoceMsgTile({
    Key? key,
    required this.tileData,
    required this.sizeFactor,
    this.enableSelection,
    this.onSelectChange,
  }) : super(key: key) {
    selfRightLayout = SharedFuncs.isSelf(tileData.userInfoM.userInfo.uid) &&
        App.app.chatServerM.properties.commonInfo?.chatLayoutMode ==
            ChatLayoutMode.SelfRight.name;
  }

  @override
  State<VoceMsgTile> createState() => _VoceMsgTileState();
}

class _VoceMsgTileState extends State<VoceMsgTile> {
  final avatarSize = VoceAvatarSize.s40;

  // final ValueNotifier<bool> selected = ValueNotifier(false);

  /// Selection icon size, also used for status icon size.
  final double selectSize = 36;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.tileData.autoDeleteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SizeTransition(
      sizeFactor: widget.sizeFactor,
      child: ValueListenableBuilder<UserInfoM?>(
          key: widget.key,
          valueListenable: widget.tileData.pinnedByUserInfoM,
          builder: (context, pinnedBy, _) {
            final isPinned = pinnedBy != null;
            return ValueListenableBuilder<bool>(
                valueListenable: widget.tileData.isAutoDeleteN,
                builder: (context, isAutoDelete, _) {
                  return Container(
                      decoration: BoxDecoration(
                        color: _getMsgTileBgColor(
                            isPinned: isPinned, isAutoDelete: isAutoDelete),
                      ),
                      constraints: BoxConstraints(
                          minHeight: avatarSize, maxWidth: width),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPinned) _buildPinnedBy(pinnedBy),
                          _buildTileWithSelectionIcon(),
                        ],
                      ));
                });
          }),
    );
  }

  Widget _buildPinnedBy(UserInfoM? pinnedBy) {
    final pinnedByName = pinnedBy?.userInfo.name;
    final name = pinnedByName == null ? "" : " $pinnedByName ";
    final locale = Localizations.localeOf(context);
    String pinStr;
    if (locale == const Locale("zh")) {
      pinStr = "被$name钉选";
    } else {
      pinStr = "pinned";
      if (pinnedByName != null) {
        pinStr += " by$name";
      }
    }
    return Container(
      height: 20,
      padding: const EdgeInsets.only(left: 56),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.pin, size: 12, color: AppColors.grey400),
          const SizedBox(width: 4),
          Flexible(
            child: Text(pinStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.grey400)),
          ),
        ],
      ),
    );
  }

  Widget _buildTileWithSelectionIcon() {
    return ValueListenableBuilder<bool>(
        valueListenable: widget.enableSelection ?? ValueNotifier(false),
        builder: (context, enableSelection, _) {
          resetSelectStatus();
          return CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: enableSelection
                ? () {
                    widget.tileData.selected.value =
                        !widget.tileData.selected.value;
                    widget.onSelectChange
                        ?.call(widget.tileData, widget.tileData.selected.value);
                  }
                : null,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSelectIcon(enableSelection, context),
              Expanded(child: _buildContentTile(context))
            ]),
          );
        });
  }

  Widget _buildSelectIcon(bool enableSelection, BuildContext context) {
    if (enableSelection) {
      return ValueListenableBuilder<bool>(
        valueListenable: widget.tileData.selected,
        builder: (context, selected, _) {
          return selected
              ? Icon(AppIcons.select, color: Colors.cyan, size: selectSize)
              : Icon(AppIcons.select,
                  color: Colors.grey[300], size: selectSize);
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildContentTile(BuildContext context) {
    if (widget.selfRightLayout) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatus(context),
          const SizedBox(width: 16),
          _buildMidCol(context),
          const SizedBox(width: 16),
          _buildAvatar()
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          _buildMidCol(context),
          const SizedBox(width: 16),
          _buildStatus(context)
        ],
      );
    }
  }

  Widget _buildAvatar() {
    return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.tileData.userInfoM.deleted
                ? null
                : () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return ContactDetailPage(
                          userInfoM: widget.tileData.userInfoM);
                    }));
                  },
            child: VoceUserAvatar.file(
                name: widget.tileData.name,
                uid: widget.tileData.userInfoM.uid,
                file: widget.tileData.avatarFile,
                size: VoceAvatarSize.s40)));
  }

  Widget _buildMidCol(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: widget.selfRightLayout
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildTitle(context),
          const SizedBox(height: 8),
          _buildContent(context),
          const SizedBox(height: 8),
          _buildReactions(context),
          _buildAutoDeleteCountDown(context)
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    List<InlineSpan> spanList = [
      TextSpan(
          text: widget.tileData.name,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF344054))),
      WidgetSpan(child: SizedBox(width: 4)),
      TextSpan(
          text: " ${widget.tileData.time.toChatTime24StrEn(context)}",
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xFFBFBFBF)))
    ];

    return Row(
        mainAxisAlignment: widget.selfRightLayout
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          RichText(
              text: TextSpan(
                  children: widget.selfRightLayout
                      ? spanList.reversed.toList()
                      : spanList)),
        ]);
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.selfRightLayout
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (widget.tileData.chatMsgMNotifier.value.isReplyMsg)
          _buildReplyBubble(),
        _buildMainContent(),
      ],
    );
  }

  Widget _buildReactions(context) {
    return ValueListenableBuilder<ChatMsgM>(
        valueListenable: widget.tileData.chatMsgMNotifier,
        builder: (context, chatMsgM, _) {
          if (!(chatMsgM.reactionData?.hasReaction ?? false)) {
            return const SizedBox();
          } else {
            var map = <String, ReactionItem>{}; // emoji: quantity

            for (var element in chatMsgM.reactionData!.reactionSet!.toList()) {
              if (!map.containsKey(element.emoji)) {
                map[element.emoji] = ReactionItem(frequency: 1);
              } else {
                map.update(element.emoji, (value) {
                  return ReactionItem(frequency: value.frequency + 1);
                });
              }

              if (element.fromUid == App.app.userDb?.uid) {
                map[element.emoji]?.isSelfReact = true;
              }
            }

            return Wrap(
                children: List<Widget>.generate(map.length, (index) {
              final reaction = map.keys.toList()[index];
              final int quantity = map[reaction]?.frequency ?? 1;
              final bool isSelf = map[reaction]?.isSelfReact ?? false;
              return Padding(
                padding: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
                child: _buildReactionTile(chatMsgM, reaction, quantity, isSelf),
              );
            }));
          }
        });
  }

  Widget _buildReactionTile(
      ChatMsgM chatMsgM, String reaction, int quantity, bool isSelf) {
    return GestureDetector(
      onTap: () {
        VoceSendService().sendReaction(chatMsgM, reaction);
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

  Widget _buildReplyBubble() {
    return VoceReplyBubble.tileData(tileData: widget.tileData);
  }

  ValueListenableBuilder<ChatMsgM> _buildMainContent() {
    return ValueListenableBuilder<ChatMsgM>(
        valueListenable: widget.tileData.chatMsgMNotifier,
        builder: (context, chatMsgM, _) {
          if (chatMsgM.isTextMsg) {
            return VoceTextBubble(chatMsgM: chatMsgM);
          } else if (chatMsgM.isMarkdownMsg) {
            return VoceMdBubble(chatMsgM: chatMsgM);
          } else if (chatMsgM.isFileMsg) {
            if (chatMsgM.isImageMsg) {
              return VoceTileImageBubble.tileData(tileData: widget.tileData);
            } else {
              final msgNormal = chatMsgM.msgNormal!;
              final path = msgNormal.content;
              final name = msgNormal.properties?["name"] ?? "";
              final size = msgNormal.properties?["size"] ?? 0;
              return VoceFileBubble(
                  filePath: path,
                  name: name,
                  size: size,
                  getLocalFile: () =>
                      FileHandler.singleton.getLocalFile(chatMsgM),
                  getFile: (onProgress) =>
                      FileHandler.singleton.getFile(chatMsgM, onProgress));
            }
          } else if (chatMsgM.isAudioMsg) {
            return VoceAudioBubble.tileData(
                tileData: widget.tileData, isSelf: widget.selfRightLayout);
          } else if (chatMsgM.isArchiveMsg) {
            return VoceArchiveBubble.tileData(tileData: widget.tileData);
          }
          return Text(AppLocalizations.of(context)!.unsupportedMessageType);
        });
  }

  Widget _buildStatus(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: widget.enableSelection ?? ValueNotifier(false),
        builder: (context, enableSelection, _) {
          if (enableSelection) {
            return const SizedBox.shrink();
          }
          return SizedBox(
            height: selectSize,
            width: selectSize,
            child: ValueListenableBuilder<MsgStatus>(
              valueListenable: widget.tileData.status,
              builder: (context, status, child) {
                switch (status) {
                  case MsgStatus.sending:
                    if (widget.tileData.chatMsgMNotifier.value
                        .shouldShowProgressWhenSending) {
                      final task = SendTaskQueue.singleton.getTask(
                          widget.tileData.chatMsgMNotifier.value.localMid);

                      if (task != null && task.progress != null) {
                        return ValueListenableBuilder<double>(
                            valueListenable: task.progress!,
                            builder: (context, p, _) {
                              final progress = p < 0.1 ? 0.1 : p;
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: CircularProgressIndicator(
                                  value: progress,
                                ),
                              );
                            });
                      }
                    }
                    return const CupertinoActivityIndicator();

                  case MsgStatus.success:
                    return const SizedBox.shrink();
                  case MsgStatus.fail:
                    return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          showAppAlert(
                              context: context,
                              title: AppLocalizations.of(context)!
                                  .chatPageResendWarning,
                              content: AppLocalizations.of(context)!
                                  .chatPageResendWarningContent,
                              actions: [
                                AppAlertDialogAction(
                                  text: AppLocalizations.of(context)!.cancel,
                                  action: () => Navigator.of(context).pop(),
                                ),
                                AppAlertDialogAction(
                                  text: AppLocalizations.of(context)!.resend,
                                  action: () {
                                    Navigator.of(context).pop();
                                    _resend();
                                  },
                                ),
                              ]);
                        },
                        child:
                            const Icon(Icons.error_outline, color: Colors.red));

                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          );
        });
  }

  Widget _buildAutoDeleteCountDown(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ValueListenableBuilder<bool>(
          valueListenable: widget.tileData.isAutoDeleteN,
          builder: (context, isAutoDelete, _) {
            if (!isAutoDelete) {
              return const SizedBox.shrink();
            } else {
              return ValueListenableBuilder<int>(
                  key: widget.key,
                  valueListenable: widget.tileData.autoDeleteCountDown,
                  builder: (context, countDown, _) {
                    return SizedBox(
                      height: 20,
                      width: double.maxFinite,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: AppColors.grey400),
                          const SizedBox(width: 4),
                          SizedBox(
                            child: Text(
                              key: widget.key,
                              _printDuration(Duration(milliseconds: countDown)),
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: AppColors.grey400,
                                fontSize: 14,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  });
            }
          }),
    );
  }

  Color _getMsgTileBgColor(
      {required bool isPinned, required bool isAutoDelete}) {
    if (isAutoDelete) {
      return const Color.fromRGBO(249, 241, 239, 1);
    } else if (isPinned) {
      return const Color.fromRGBO(239, 252, 255, 1);
    } else {
      return Colors.white;
    }
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    // Days
    if (duration.inDays > 1) {
      return duration.inDays.toString() + AppLocalizations.of(context)!.days;
    } else if (duration.inDays > 0) {
      return "1${AppLocalizations.of(context)!.day}";
    }

    // Hours
    else if (duration.inHours > 1) {
      return duration.inHours.toString() + AppLocalizations.of(context)!.hours;
    } else if (duration.inHours > 0) {
      return "1${AppLocalizations.of(context)!.hour}";
    }

    // Minutes
    else if (duration.inMinutes > 1) {
      return duration.inMinutes.toString() +
          AppLocalizations.of(context)!.minutes;
    } else if (duration.inMinutes > 0) {
      return "1${AppLocalizations.of(context)!.minute}";
    }

    // Last minute
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return twoDigitSeconds;
  }

  void resetSelectStatus() {
    widget.tileData.selected.value = false;
  }

  void _resend() async {
    final chatMsgM = widget.tileData.chatMsgMNotifier.value;
    if (chatMsgM.status != MsgStatus.fail) {
      return;
    }

    if (chatMsgM.isGroupMsg) {
      if (chatMsgM.detailContentType == MsgContentType.text) {
        if (chatMsgM.isReplyMsg) {
          final content = chatMsgM.msgReply!.content;
          final targetMid = chatMsgM.msgReply!.mid;
          VoceSendService().sendChannelReply(chatMsgM.gid, targetMid, content,
              resendLocalMid: chatMsgM.localMid);
        } else {
          final content =
              chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? '';
          VoceSendService().sendChannelText(chatMsgM.gid, content,
              resendLocalMid: chatMsgM.localMid);
        }
      } else if (chatMsgM.detailContentType == MsgContentType.file) {
        await FileHandler.singleton.getLocalFile(chatMsgM).then((file) {
          if (file == null) {
            showAppAlert(
                context: context,
                title:
                    AppLocalizations.of(context)!.chatPageCantFindFileWarning,
                content: AppLocalizations.of(context)!
                    .chatPageCantFindFileWarningContent,
                actions: [
                  AppAlertDialogAction(
                      text: AppLocalizations.of(context)!.ok,
                      action: () => Navigator.of(context).pop())
                ]);
          } else {
            VoceSendService().sendChannelFile(chatMsgM.gid, file.path,
                resendLocalMid: chatMsgM.localMid);
          }
        });
      } else if (chatMsgM.detailContentType == MsgContentType.audio) {
        await AudioFileHandler()
            .readAudioFile(chatMsgM, serverFetch: false)
            .then((file) {
          if (file == null) {
            showAppAlert(
                context: context,
                title:
                    AppLocalizations.of(context)!.chatPageCantFindFileWarning,
                content: AppLocalizations.of(context)!
                    .chatPageCantFindFileWarningContent,
                actions: [
                  AppAlertDialogAction(
                      text: AppLocalizations.of(context)!.ok,
                      action: () => Navigator.of(context).pop())
                ]);
          } else {
            VoceSendService()
                .sendChannelAudio(chatMsgM.gid, chatMsgM.localMid, file);
          }
        });
      } else if (chatMsgM.detailContentType == MsgContentType.archive) {
        showAppAlert(
            context: context,
            title: AppLocalizations.of(context)!.error,
            content: AppLocalizations.of(context)!.resendNotSupported,
            actions: [
              AppAlertDialogAction(
                  text: AppLocalizations.of(context)!.ok,
                  action: () => Navigator.of(context).pop())
            ]);
      }
    } else {
      if (chatMsgM.detailContentType == MsgContentType.text) {
        if (chatMsgM.isReplyMsg) {
          final content = chatMsgM.msgReply!.content;
          final targetMid = chatMsgM.msgReply!.mid;
          VoceSendService().sendUserReply(chatMsgM.dmUid, targetMid, content,
              resendLocalMid: chatMsgM.localMid);
        } else {
          final content =
              chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? '';
          VoceSendService().sendUserText(chatMsgM.dmUid, content,
              resendLocalMid: chatMsgM.localMid);
        }
      } else if (chatMsgM.detailContentType == MsgContentType.file) {
        await FileHandler.singleton.getLocalFile(chatMsgM).then((file) {
          if (file == null) {
            showAppAlert(
                context: context,
                title:
                    AppLocalizations.of(context)!.chatPageCantFindFileWarning,
                content: AppLocalizations.of(context)!
                    .chatPageCantFindFileWarningContent,
                actions: [
                  AppAlertDialogAction(
                      text: AppLocalizations.of(context)!.ok,
                      action: () => Navigator.of(context).pop())
                ]);
          } else {
            VoceSendService().sendUserFile(chatMsgM.dmUid, file.path,
                resendLocalMid: chatMsgM.localMid);
          }
        });
      } else if (chatMsgM.detailContentType == MsgContentType.audio) {
        await AudioFileHandler()
            .readAudioFile(chatMsgM, serverFetch: false)
            .then((file) {
          if (file == null) {
            showAppAlert(
                context: context,
                title:
                    AppLocalizations.of(context)!.chatPageCantFindFileWarning,
                content: AppLocalizations.of(context)!
                    .chatPageCantFindFileWarningContent,
                actions: [
                  AppAlertDialogAction(
                      text: AppLocalizations.of(context)!.ok,
                      action: () => Navigator.of(context).pop())
                ]);
          } else {
            VoceSendService()
                .sendUserAudio(chatMsgM.dmUid, chatMsgM.localMid, file);
          }
        });
      } else if (chatMsgM.detailContentType == MsgContentType.archive) {
        showAppAlert(
            context: context,
            title: AppLocalizations.of(context)!.error,
            content: AppLocalizations.of(context)!.resendNotSupported,
            actions: [
              AppAlertDialogAction(
                  text: AppLocalizations.of(context)!.ok,
                  action: () => Navigator.of(context).pop())
            ]);
      }
    }
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
