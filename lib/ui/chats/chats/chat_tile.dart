import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vocechat_client/app_text_styles.dart';
import 'package:vocechat_client/helpers/time_helper.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';

class ChatTile extends StatefulWidget {
  final Widget? avatar;
  late final Widget _avatar;
  final ValueNotifier<String> name;
  final ValueNotifier<String> snippet;
  final ValueNotifier<int> updatedAt;
  final ValueNotifier<String> draft;
  final ValueNotifier<int> unreadCount;
  final ValueNotifier<int> unreadMentionCount;
  final ValueNotifier<bool> isMuted;
  final bool isPrivateChannel;
  final Function()? onTap;

  late bool _hasDraft;

  ChatTile(
      {required this.name,
      required this.snippet,
      required this.updatedAt,
      required this.draft,
      required this.unreadCount,
      required this.unreadMentionCount,
      this.avatar,
      required this.isMuted,
      this.isPrivateChannel = false,
      this.onTap}) {
    _hasDraft = draft.value.isNotEmpty;

    if (avatar == null) {
      _avatar = ValueListenableBuilder<String>(
          valueListenable: name,
          builder: (context, name, _) {
            return CircleAvatar(child: Text(name.substring(0, 1)), radius: 24);
          });
    } else {
      _avatar = avatar!;
    }
  }

  @override
  State<ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  late Widget avatar;

  @override
  void initState() {
    super.initState();
    avatar = widget._avatar;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: widget.onTap,
      leading: widget._avatar,
      horizontalTitleGap: 16,
      dense: true,
      title: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
                child: Row(
              children: [
                Flexible(
                  child: ValueListenableBuilder<String>(
                      valueListenable: widget.name,
                      builder: (context, name, _) {
                        return Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium(),
                          strutStyle: StrutStyle(fontSize: 16, height: 1.3),
                        );
                      }),
                ),
                if (widget.isPrivateChannel)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.lock, size: 16),
                  ),
              ],
            )),
            ValueListenableBuilder<int>(
                valueListenable: widget.updatedAt,
                builder: (context, updatedAt, _) {
                  if (updatedAt == 0) {
                    return SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                        DateTime.fromMillisecondsSinceEpoch(updatedAt)
                            .toTime24StringEn(),
                        strutStyle: StrutStyle(forceStrutHeight: true),
                        style: AppTextStyles.labelSmall()),
                  );
                })
          ],
        ),
      ),
      subtitle: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ValueListenableBuilder<String>(
              valueListenable: widget.draft,
              builder: (context, draft, _) {
                if (draft.isNotEmpty) {
                  return Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.create, color: Colors.red, size: 18),
                      ),
                      Text(draft,
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.w400))
                    ],
                  );
                }
                return Expanded(
                    child: ValueListenableBuilder<String>(
                        valueListenable: widget.snippet,
                        builder: (context, snippet, _) {
                          // print('the last chat message is $snippet');
                          return Text(
                            snippet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            strutStyle: StrutStyle(forceStrutHeight: true),
                            style: AppTextStyles.snippet(),
                          );
                        }));
                // snippet
              }),
          ValueListenableBuilder<int>(
              valueListenable: widget.unreadMentionCount,
              builder: (context, value, _) {
                if (value > 0) {
                  return Container(
                      constraints: BoxConstraints(minWidth: 16),
                      height: 16,
                      decoration: BoxDecoration(
                          color: AppColors.systemRed,
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            "$value",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10),
                          ),
                        ),
                      ));
                } else {
                  return ValueListenableBuilder<int>(
                      valueListenable: widget.unreadCount,
                      builder: (context, value, _) {
                        if (value < 1) {
                          return SizedBox.shrink();
                        }
                        return Container(
                            constraints: BoxConstraints(minWidth: 16),
                            height: 16,
                            decoration: BoxDecoration(
                                color: AppColors.primaryHover,
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  "$value",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10),
                                ),
                              ),
                            ));
                      });
                }
              })
        ],
      ),
    );
  }
}
