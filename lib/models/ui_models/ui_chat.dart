import 'dart:typed_data';

import 'package:flutter/material.dart';

class UiChat {
  // snippet, unreadCount, updatedAt,

  // Rebuild UI when changing avatar.
  ValueNotifier<Uint8List> avatar = ValueNotifier(Uint8List(0));

  int? gid;
  int? uid;

  ValueNotifier<String> title = ValueNotifier("");
  ValueNotifier<String> snippet = ValueNotifier("");
  ValueNotifier<int> unreadCount = ValueNotifier(0);
  ValueNotifier<bool> isMuted = ValueNotifier(false);

  /// The number of mentions in a channel chat.
  /// Only channel has this attribute
  ///
  /// Do not display mention if value is 0.
  ValueNotifier<int> unreadMentionCount = ValueNotifier(0);

  /// Timestamp when there is a new message update.
  ValueNotifier<int> updatedAt = ValueNotifier(0);
  ValueNotifier<String> draft = ValueNotifier("");
  late final bool isChannel;
  ValueNotifier<bool> isPrivateChannel = ValueNotifier(false);

  /// Whether to allow user to hide this tile.
  /// Channels can't be hidden by default.
  late bool enableHide;

  /// Indicates the online status of a user.
  ///
  /// Only available for Direct Messages.
  ValueNotifier<bool>? onlineNotifier;

  UiChat(
      {Uint8List? avatar,
      String title = "Deleted User",
      this.gid,
      this.uid,
      bool isMuted = false,
      String snippet = "",
      int unreadCount = 0,
      int unreadMentionCount = 0,
      int updatedAt = 0,
      String draft = "",
      bool isPrivateChannel = false,
      this.enableHide = false,
      this.onlineNotifier}) {
    // Between Channel id (group id, or gid) and uid, only one exists.
    assert((gid == null && uid != null) || (gid != null && uid == null));

    isChannel = (gid != null && uid == null);

    this.avatar.value = avatar ?? Uint8List(0);
    this.title.value = title;
    this.snippet.value = snippet;
    this.unreadCount.value = unreadCount;
    this.unreadMentionCount.value = unreadMentionCount;
    this.updatedAt.value = updatedAt;
    this.isMuted.value = isMuted;
    this.draft.value = draft;
    this.isPrivateChannel.value = isPrivateChannel;

    enableHide = !isChannel;
  }

  // UiChat.fromUserInfoM({required UserInfoM userInfoM}) {
  //   avatar = userInfoM.avatarBytes;
  //   title = userInfoM.userInfo.name;
  //   uid = userInfoM.uid;
  //   snippet = userInfoM.properties.
  // }
}
