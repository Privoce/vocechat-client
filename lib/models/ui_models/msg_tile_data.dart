import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app.dart';
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
  final ValueKey key;

  // Tile frame data
  // int avatarUpdatedAt = 0;
  File? avatarFile;
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
  ValueNotifier<ChatMsgM?> repliedMsgMNotifier = ValueNotifier(null);
  UserInfoM? repliedUserInfoM;

  // Pinned message, only for channels
  ValueNotifier<UserInfoM?> pinnedByUserInfoM = ValueNotifier(null);

  /// Reply message is an image
  File? repliedImageFile;

  // Reply message is an audio
  // File? repliedAudioFile;
  AudioInfo? repliedAudioInfo;

  // For auto-delete messages
  ValueNotifier<bool> isAutoDeleteN = ValueNotifier(false);
  ValueNotifier<int> autoDeleteCountDown = ValueNotifier(0);
  Timer? autoDeleteTimer;

  // For multi-message selection
  final ValueNotifier<bool> selected = ValueNotifier(false);

  // Constructors
  MsgTileData(
      {required ChatMsgM chatMsgM, required this.userInfoM, this.avatarFile})
      : key = ValueKey(chatMsgM.localMid) {
    chatMsgMNotifier = ValueNotifier(chatMsgM);
    setGeneralData();
    initAutoDeleteTimer();
  }

  void setGeneralData() {
    final chatMsgM = chatMsgMNotifier.value;

    name = userInfoM.userInfo.name;
    time = chatMsgM.createdAt;

    chatMsgMNotifier.addListener(msgListener);

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
  void msgListener() {
    status.value = chatMsgMNotifier.value.status;

    final chatMsgM = chatMsgMNotifier.value;
    final isAutoDelete = (chatMsgM.msgNormal?.expiresIn != null &&
            chatMsgM.msgNormal!.expiresIn! > 0) ||
        (chatMsgM.msgReply?.expiresIn != null &&
            chatMsgM.msgReply!.expiresIn! > 0);

    if (!isAutoDelete) {
      autoDeleteTimer?.cancel();
    } else {
      initAutoDeleteTimer();
    }

    isAutoDeleteN.value = isAutoDelete;
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
      if (chatMsgMNotifier.value.isImageMsg) {
        await setNormalImage(serverFetch: false);
      } else if (chatMsgMNotifier.value.isAudioMsg) {
        await setNormalAudio(serverFetch: false);
      } else if (chatMsgMNotifier.value.isArchiveMsg) {
        await setNormalArchive(serverFetch: false);
      }
    } else if (chatMsgMNotifier.value.isReplyMsg) {
      // Replied message is a text/markdown/file/image/audio/archive
      // Reply message only contains text
      await setReplyGeneralData();
      if (repliedMsgMNotifier.value == null) return;

      if (repliedMsgMNotifier.value!.isImageMsg) {
        await setRepliedImage(serverFetch: false);
      } else if (repliedMsgMNotifier.value!.isAudioMsg) {
        await setRepliedAudio(serverFetch: false);
      } else if (repliedMsgMNotifier.value!.isArchiveMsg) {
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
      if (repliedMsgMNotifier.value == null) return;

      if (repliedMsgMNotifier.value!.isImageMsg) {
        await setRepliedImage();
      } else if (repliedMsgMNotifier.value!.isAudioMsg) {
        await setRepliedAudio();
      } else if (repliedMsgMNotifier.value!.isArchiveMsg) {
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
      if (repliedMsgMNotifier.value == null) return false;

      if (repliedMsgMNotifier.value!.isImageMsg) {
        return repliedImageFile == null;
      } else if (repliedMsgMNotifier.value!.isAudioMsg) {
        return repliedAudioInfo == null;
      } else if (repliedMsgMNotifier.value!.isArchiveMsg) {
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

    repliedMsgMNotifier.value = repliedMsgM;
    if (repliedMsgMNotifier.value == null) {
      return;
    }

    repliedUserInfoM =
        await UserInfoDao().getUserByUid(repliedMsgMNotifier.value!.fromUid);
  }

  Future<void> setRepliedImage({bool serverFetch = true}) async {
    assert(chatMsgMNotifier.value.isReplyMsg &&
        repliedMsgMNotifier.value!.isImageMsg);

    // TODO: If an image message has been deleted, will the original image
    //  still be accessible through resource apis?

    if (repliedMsgMNotifier.value == null) return;

    if (repliedMsgMNotifier.value!.isGifImageMsg) {
      if (serverFetch) {
        repliedImageFile = await FileHandler.singleton
            .getImageNormal(repliedMsgMNotifier.value!);
      } else {
        repliedImageFile = await FileHandler.singleton
            .getLocalImageNormal(repliedMsgMNotifier.value!);
      }
    } else {
      if (serverFetch) {
        repliedImageFile = await FileHandler.singleton
            .getImageThumb(repliedMsgMNotifier.value!);
      } else {
        repliedImageFile = await FileHandler.singleton
            .getLocalImageThumb(repliedMsgMNotifier.value!);
      }
    }
  }

  Future<void> setRepliedAudio({bool serverFetch = true}) async {
    assert(chatMsgMNotifier.value.isReplyMsg &&
        repliedMsgMNotifier.value!.isAudioMsg);

    final repliedAudioFile = await AudioFileHandler()
        .readAudioFile(repliedMsgMNotifier.value!, serverFetch: serverFetch);

    if (repliedAudioFile == null) return;

    final player = AudioPlayer();
    await player.setSource(DeviceFileSource(repliedAudioFile.path));
    final duration = await player.getDuration();

    repliedAudioInfo = AudioInfo(player, duration?.inMilliseconds ?? 0);
  }

  Future<void> setRepliedArchive({bool serverFetch = true}) async {
    assert(chatMsgMNotifier.value.isReplyMsg &&
        repliedMsgMNotifier.value!.isArchiveMsg);

    final archiveM = await ArchiveHandler()
        .getArchive(repliedMsgMNotifier.value!, serverFetch: serverFetch);
    if (archiveM != null) {
      archive = archiveM.archive;
    }
  }

  void initAutoDeleteTimer() {
    final chatMsgM = chatMsgMNotifier.value;
    if (isAutoDelete) {
      isAutoDeleteN.value = true;
      autoDeleteTimer?.cancel();
      autoDeleteCountDown.value = _getAutoDeletionRemains();

      if (autoDeleteCountDown.value > 0 &&
          (autoDeleteTimer == null || !autoDeleteTimer!.isActive)) {
        autoDeleteTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          autoDeleteCountDown.value -= 1000;
          if (autoDeleteCountDown.value <= 0) {
            ChatMsgDao().deleteMsgByLocalMid(chatMsgM).then((value) async {
              App.app.chatService.fireLmidDelete(chatMsgM.localMid);

              FileHandler.singleton.deleteWithChatMsgM(chatMsgM);
              AudioFileHandler().deleteWithChatMsgM(chatMsgM);

              int curMaxMid;

              if (chatMsgM.isGroupMsg) {
                curMaxMid = await ChatMsgDao().getChannelMaxMid(chatMsgM.gid);
              } else {
                curMaxMid = await ChatMsgDao().getDmMaxMid(chatMsgM.dmUid);
              }

              if (curMaxMid > -1) {
                final latestMsgM = await ChatMsgDao().getMsgByMid(curMaxMid);

                if (latestMsgM != null) {
                  App.app.chatService
                      .fireMsg(latestMsgM, true, snippetOnly: true);
                }
              }
            });
            autoDeleteTimer?.cancel();
          }
        });
      }
    }
  }

  int _getAutoDeletionRemains() {
    final chatMsgM = chatMsgMNotifier.value;
    if (isAutoDelete) {
      final expiresIn = chatMsgM.msgNormal?.expiresIn;
      if (expiresIn != null && expiresIn > 0) {
        final currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
        final msgTimeStamp = chatMsgM.createdAt;

        final dif = msgTimeStamp + expiresIn * 1000 - currentTimeStamp;
        if (dif < 0) {
          return 0;
        } else {
          return dif;
        }
      }
    }
    return -1;
  }
}
