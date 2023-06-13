import 'package:flutter/material.dart';
import 'package:vocechat_client/helpers/time_helper.dart';
import 'package:vocechat_client/models/ui_models/chat_tile_data.dart';
import 'package:vocechat_client/ui/app_colors.dart';
import 'package:vocechat_client/ui/app_icons_icons.dart';
import 'package:vocechat_client/ui/app_text_styles.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_avatar_size.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_channel_avatar.dart';
import 'package:vocechat_client/ui/widgets/avatar/voce_user_avatar.dart';

class VoceChatTile extends StatelessWidget {
  final ChatTileData tileData;
  final void Function(ChatTileData tileData) onTap;

  const VoceChatTile({Key? key, required this.tileData, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: tileData.isPinned,
      builder: (context, pinned, child) {
        final bgColor = pinned ? Colors.grey[200] : Colors.transparent;
        return Container(
          color: bgColor,
          child: child,
        );
      },
      child: ListTile(
        onTap: () => onTap(tileData),
        leading: _buildAvatar(),
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
                        valueListenable: tileData.title,
                        builder: (context, name, _) {
                          return Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium,
                            strutStyle:
                                const StrutStyle(fontSize: 16, height: 1.3),
                          );
                        }),
                  ),
                  ValueListenableBuilder<bool>(
                      valueListenable: tileData.isPrivateChannel,
                      builder: (context, isPrivate, _) {
                        if (isPrivate) {
                          return const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.lock, size: 16),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),
                ],
              )),
              ValueListenableBuilder<int>(
                  valueListenable: tileData.updatedAt,
                  builder: (context, updatedAt, _) {
                    if (updatedAt == 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                          DateTime.fromMillisecondsSinceEpoch(updatedAt)
                              .toTime24StringEn(context),
                          strutStyle: const StrutStyle(forceStrutHeight: true),
                          style: AppTextStyles.labelSmall),
                    );
                  })
            ],
          ),
        ),
        subtitle: _buildSubtitle(),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ValueListenableBuilder<String>(
            valueListenable: tileData.draft,
            builder: (context, draft, _) {
              if (draft.isNotEmpty) {
                return Expanded(
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.create, color: Colors.red, size: 18),
                      ),
                      Flexible(
                        child: Text(draft,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                color: Colors.red,
                                fontWeight: FontWeight.w400)),
                      )
                    ],
                  ),
                );
              }
              return Expanded(
                  child: ValueListenableBuilder<String>(
                      valueListenable: tileData.snippet,
                      builder: (context, snippet, _) {
                        return Text(
                          snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          strutStyle: const StrutStyle(forceStrutHeight: true),
                          style: AppTextStyles.snippet,
                        );
                      }));
              // snippet
            }),
        _buildSubtitleBadge()
      ],
    );
  }

  Widget _buildSubtitleBadge() {
    return ValueListenableBuilder<bool>(
        valueListenable: tileData.isMuted,
        builder: (context, isMuted, _) {
          if (isMuted) {
            return Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                AppIcons.mute,
                size: 14,
                color: AppColors.grey500,
              ),
            );
          } else {
            return ValueListenableBuilder<int>(
                valueListenable: tileData.mentionsCount,
                builder: (context, value, _) {
                  if (value > 0) {
                    return Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        decoration: BoxDecoration(
                            color: AppColors.systemRed,
                            borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              "$value",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10),
                            ),
                          ),
                        ));
                  } else {
                    return ValueListenableBuilder<int>(
                        valueListenable: tileData.unreadCount,
                        builder: (context, value, _) {
                          if (value < 1) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                              constraints: const BoxConstraints(minWidth: 16),
                              margin: const EdgeInsets.only(left: 4),
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
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10),
                                  ),
                                ),
                              ));
                        });
                  }
                });
          }
        });
  }

  Widget _buildAvatar() {
    return ValueListenableBuilder(
      valueListenable: tileData.avatarUpdatedAt,
      builder: (context, value, child) {
        if (tileData.isChannel) {
          return VoceChannelAvatar.channel(
              groupInfoM: tileData.groupInfoM!.value, size: VoceAvatarSize.s48);
        } else {
          return VoceUserAvatar.user(
              userInfoM: tileData.userInfoM!.value, size: VoceAvatarSize.s48);
        }
      },
    );
  }
}
