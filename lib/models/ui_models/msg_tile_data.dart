import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/models/ui_models/audio_info.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/file_handler/archive_handler.dart';
import 'package:vocechat_client/services/file_handler/audio_file_handler.dart';
import 'package:vocechat_client/services/send_task_queue/send_task_queue.dart';
import 'package:vocechat_client/shared_funcs.dart';

class MsgTileData {
  // General Data
  late ValueNotifier<ChatMsgM> chatMsgMNotifier;
  UserInfoM userInfoM;

  // Tile frame data
  int avatarUpdatedAt = 0;
  String name = "";
  int time = 0;
  ValueNotifier<MsgStatus> status = ValueNotifier(MsgStatus.success);

  /// Only for files (images and files)
  ValueNotifier<double> progress = ValueNotifier(0);

  // Specific data for different types of messages
  // File for image. Files will not be preloaded for pure file messages.
  File? imageFile;

  // Audio
  // AudioInfoState? audioInfo;
  // File? audioFile;
  AudioInfo? audioInfo;

  // Archive
  Archive? archive;

  // Reply message
  // Reply message is a text or markdown message
  ValueNotifier<ChatMsgM>? repliedMsgMNotifier;
  UserInfoM? repliedUserInfoM;

  // Pinned message, only for channels
  ValueNotifier<UserInfoM?> pinnedByUserInfoM = ValueNotifier(null);

  /// Reply message is an image
  File? repliedImageFile;

  // Reply message is an audio
  // File? repliedAudioFile;
  AudioInfo? repliedAudioInfo;

  // Constructors
  MsgTileData({required ChatMsgM chatMsgM, required this.userInfoM}) {
    chatMsgMNotifier = ValueNotifier(chatMsgM);
    setGeneralData();
  }

  void setGeneralData() {
    final chatMsgM = chatMsgMNotifier.value;

    avatarUpdatedAt = userInfoM.userInfo.avatarUpdatedAt;
    name = userInfoM.userInfo.name;
    time = chatMsgM.createdAt;

    chatMsgMNotifier.addListener(statusListener);

    // Still need the following for initial status.
    MsgStatus status = chatMsgMNotifier.value.status;
    if (status != MsgStatus.success) {
      status = SendTaskQueue.singleton
              .isWaitingOrExecuting(chatMsgMNotifier.value.localMid)
          ? MsgStatus.sending
          : status;
    }

    this.status.value = status;
  }

  // -- Subscriptions
  void statusListener() {
    status.value = chatMsgMNotifier.value.status;
  }

  // -- Property getters
  bool get isSelf => SharedFuncs.isSelf(chatMsgMNotifier.value.fromUid);
  bool get isChannel => chatMsgMNotifier.value.isGroupMsg;
  bool get isAutoDelete =>
      (chatMsgMNotifier.value.msgNormal?.expiresIn != null &&
          chatMsgMNotifier.value.msgNormal!.expiresIn! > 0) ||
      (chatMsgMNotifier.value.msgReply?.expiresIn != null &&
          chatMsgMNotifier.value.msgReply!.expiresIn! > 0);

  // Async secondary setters

  /// Prepare only the essential data for the chat page.
  ///
  /// Only fetches local data.
  Future<void> primaryPrepare() async {
    setGeneralData();

    if (isChannel && chatMsgMNotifier.value.pin > 0) {
      final pinnedBy = chatMsgMNotifier.value.pin;
      pinnedByUserInfoM.value = await UserInfoDao().getUserByUid(pinnedBy);
    } else {
      pinnedByUserInfoM.value = null;
    }

    if (chatMsgMNotifier.value.isNormalMsg) {
      // If is text/markdown/file/image/audio, do nothing.
      if (chatMsgMNotifier.value.isArchiveMsg) {
        await setNormalArchive(serverFetch: false);
      }
    } else if (chatMsgMNotifier.value.isReplyMsg) {
      // Replied message is a text/markdown/file/image/audio/archive
      // Reply message only contains text
      await setReplyGeneralData();
      if (repliedMsgMNotifier == null) return;

      if (repliedMsgMNotifier!.value.isArchiveMsg) {
        await setRepliedArchive(serverFetch: false);
      }
    }
  }

  /// Prepare the local and server data for the chat page.
  ///
  /// Fetches full data for messages.
  /// Fetches local data first, if no local data is found, it fetches server data.
  Future<void> secondaryPrepare() async {
    if (chatMsgMNotifier.value.isNormalMsg) {
      // If is text/markdown/file, do nothing.
      if (chatMsgMNotifier.value.isImageMsg) {
        await setNormalImage();
      } else if (chatMsgMNotifier.value.isAudioMsg) {
        await setNormalAudio();
      } else if (chatMsgMNotifier.value.isArchiveMsg) {
        await setNormalArchive();
      }
    } else if (chatMsgMNotifier.value.isReplyMsg) {
      // Replied message is a text/markdown/file/image/audio/archive
      // Reply message only contains text
      await setReplyGeneralData();
      if (repliedMsgMNotifier == null) return;

      if (repliedMsgMNotifier!.value.isImageMsg) {
        await setRepliedImage();
      } else if (repliedMsgMNotifier!.value.isAudioMsg) {
        await setRepliedAudio();
      } else if (repliedMsgMNotifier!.value.isArchiveMsg) {
        await setRepliedArchive();
      }
    }
  }

  /// Whether the message needs to be prepared by visiting server resources.
  ///
  /// Judged by whether the local files is empty. If so, it means no local files
  /// are found, and the resources need to be downloaded from server.
  bool get needSecondaryPrepare {
    if (chatMsgMNotifier.value.isNormalMsg) {
      // If is text/markdown/file, do nothing.
      if (chatMsgMNotifier.value.isImageMsg) {
        return imageFile == null;
      } else if (chatMsgMNotifier.value.isAudioMsg) {
        return audioInfo == null;
      } else if (chatMsgMNotifier.value.isArchiveMsg) {
        return archive == null;
      }
    } else if (chatMsgMNotifier.value.isReplyMsg) {
      // Replied message is a text/markdown/file/image/audio/archive
      // Reply message only contains text
      if (repliedMsgMNotifier == null) return false;

      if (repliedMsgMNotifier!.value.isImageMsg) {
        return repliedImageFile == null;
      } else if (repliedMsgMNotifier!.value.isAudioMsg) {
        return repliedAudioInfo == null;
      } else if (repliedMsgMNotifier!.value.isArchiveMsg) {
        return archive == null;
      }
    }

    return false;
  }

  Future<void> setNormalImage({bool serverFetch = true}) async {
    assert(chatMsgMNotifier.value.isNormalMsg &&
        chatMsgMNotifier.value.isImageMsg);

    if (chatMsgMNotifier.value.isGifImageMsg) {
      if (serverFetch) {
        imageFile =
            await FileHandler.singleton.getImageNormal(chatMsgMNotifier.value);
      } else {
        imageFile = await FileHandler.singleton
            .getLocalImageNormal(chatMsgMNotifier.value);
      }
    } else {
      if (serverFetch) {
        imageFile =
            await FileHandler.singleton.getImageThumb(chatMsgMNotifier.value);
      } else {
        imageFile = await FileHandler.singleton
            .getLocalImageThumb(chatMsgMNotifier.value);
      }
    }
  }

  Future<void> setNormalAudio({bool serverFetch = true}) async {
    assert(chatMsgMNotifier.value.isNormalMsg &&
        chatMsgMNotifier.value.isAudioMsg);

    final audioFile = await AudioFileHandler()
        .readAudioFile(chatMsgMNotifier.value, serverFetch: serverFetch);
    if (audioFile == null) return;

    final player = AudioPlayer();

    await player.setSource(DeviceFileSource(audioFile.path));
    player.setReleaseMode(ReleaseMode.stop);

    final duration = await player.getDuration();
    audioInfo = AudioInfo(player, duration?.inMilliseconds ?? 0);
  }

  Future<void> setNormalArchive({bool serverFetch = true}) async {
    assert(chatMsgMNotifier.value.isNormalMsg &&
        chatMsgMNotifier.value.isArchiveMsg);

    final archiveM = await ArchiveHandler()
        .getArchive(chatMsgMNotifier.value, serverFetch: serverFetch);
    if (archiveM != null) {
      archive = archiveM.archive;
    }
  }

  /// Prepare the reply message data for the chat page.
  ///
  /// Set general data for reply messages which is shared by all replies.
  /// Only includes local data.
  Future<void> setReplyGeneralData() async {
    assert(chatMsgMNotifier.value.isReplyMsg);

    int? targetMid = chatMsgMNotifier.value.msgReply?.mid;
    if (targetMid == null) {
      return;
    }

    final repliedMsgM = await ChatMsgDao().getMsgByMid(targetMid);

    if (repliedMsgM == null) return;

    repliedMsgMNotifier = ValueNotifier(repliedMsgM);
    if (repliedMsgMNotifier == null) {
      return;
    }

    repliedUserInfoM =
        await UserInfoDao().getUserByUid(repliedMsgMNotifier!.value.fromUid);
  }

  Future<void> setRepliedImage({bool serverFetch = true}) async {
    assert(chatMsgMNotifier.value.isReplyMsg &&
        repliedMsgMNotifier!.value.isImageMsg);

    // TODO: If an image message has been deleted, will the original image
    //  still be accessible through resource apis?

    if (repliedMsgMNotifier == null) return;

    if (repliedMsgMNotifier!.value.isGifImageMsg) {
      if (serverFetch) {
        repliedImageFile = await FileHandler.singleton
            .getImageNormal(repliedMsgMNotifier!.value);
      } else {
        repliedImageFile = await FileHandler.singleton
            .getLocalImageNormal(repliedMsgMNotifier!.value);
      }
    } else {
      if (serverFetch) {
        repliedImageFile = await FileHandler.singleton
            .getImageThumb(repliedMsgMNotifier!.value);
      } else {
        repliedImageFile = await FileHandler.singleton
            .getLocalImageThumb(repliedMsgMNotifier!.value);
      }
    }
  }

  Future<void> setRepliedAudio({bool serverFetch = true}) async {
    assert(chatMsgMNotifier.value.isReplyMsg &&
        repliedMsgMNotifier!.value.isAudioMsg);

    final repliedAudioFile = await AudioFileHandler()
        .readAudioFile(repliedMsgMNotifier!.value, serverFetch: serverFetch);

    if (repliedAudioFile == null) return;

    final player = AudioPlayer();
    await player.setSource(DeviceFileSource(repliedAudioFile.path));
    final duration = await player.getDuration();

    repliedAudioInfo = AudioInfo(player, duration?.inMilliseconds ?? 0);
  }

  Future<void> setRepliedArchive({bool serverFetch = true}) async {
    assert(chatMsgMNotifier.value.isReplyMsg &&
        repliedMsgMNotifier!.value.isArchiveMsg);

    final archiveM = await ArchiveHandler()
        .getArchive(repliedMsgMNotifier!.value, serverFetch: serverFetch);
    if (archiveM != null) {
      archive = archiveM.archive;
    }
  }
}
