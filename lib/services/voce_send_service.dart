import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:vocechat_client/api/lib/group_api.dart';
import 'package:vocechat_client/api/lib/message_api.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/api/models/msg/chat_msg.dart';
import 'package:vocechat_client/api/models/msg/msg_normal.dart';
import 'package:vocechat_client/api/models/msg/msg_reply.dart';
import 'package:vocechat_client/api/models/msg/msg_target_group.dart';
import 'package:vocechat_client/api/models/msg/msg_target_user.dart';
import 'package:vocechat_client/api/models/resource/file_prepare_request.dart';
import 'package:vocechat_client/api/models/resource/file_upload_response.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_consts.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/main.dart';
import 'package:vocechat_client/models/local_kits.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/file_uploader.dart';
import 'package:vocechat_client/services/send_task_queue/send_task_queue.dart';

import 'package:path/path.dart' as p;
import 'package:vocechat_client/shared_funcs.dart';
import 'package:vocechat_client/ui/app_alert_dialog.dart';

class VoceSendService {
  static final VoceSendService _voceSendService = VoceSendService._internal();

  factory VoceSendService() {
    return _voceSendService;
  }

  VoceSendService._internal();

  Future<void> sendUserText(int uid, String content,
      {String? resendLocalMid}) async {
    final fakeMid = await _getFakeMid();
    final localMid = resendLocalMid ?? uuid();
    final expiresIn =
        (await UserInfoDao().getUserByUid(uid))?.properties.burnAfterReadSecond;

    final chatMsgDao = ChatMsgDao();

    final detail = MsgNormal(
        properties: {"cid": localMid},
        contentType: typeText,
        expiresIn: expiresIn,
        content: content);
    final message = ChatMsg(
        target: MsgTargetUser(uid).toJson(),
        mid: fakeMid,
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());
    ChatMsgM chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.fail);

    await chatMsgDao.add(chatMsgM).then((_) async {
      final toBeFired = ChatMsgM.fromMsg(message, localMid, MsgStatus.sending);
      App.app.chatService.fireMsg(toBeFired, true);

      await UserApi().sendTextMsg(uid, content, localMid).then(
        (response) async {
          if (response.statusCode == 200) {
            final mid = response.data!;
            message.mid = mid;
            chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.success);
            await chatMsgDao.update(chatMsgM).then((value) {
              App.app.chatService.fireMsg(chatMsgM, true);
            }).onError((error, stackTrace) {
              App.logger.severe(error);
              App.app.chatService
                  .fireMsg(chatMsgM..status = MsgStatus.fail, true);
            });
          } else {
            App.logger.severe(
                "Message send failed, statusCode: ${response.statusCode}");
            App.app.chatService
                .fireMsg(chatMsgM..status = MsgStatus.fail, true);
          }
        },
      ).onError((error, stackTrace) {
        App.logger.severe(error);
        App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
      });
    });
  }

  Future<void> sendUserReply(int uid, int targetMid, String content,
      {String? resendLocalMid}) async {
    final fakeMid = await _getFakeMid();
    final localMid = resendLocalMid ?? uuid();
    final expiresIn =
        (await UserInfoDao().getUserByUid(uid))?.properties.burnAfterReadSecond;

    final chatMsgDao = ChatMsgDao();

    final detail = MsgReply(
        properties: {"cid": localMid},
        contentType: typeText,
        expiresIn: expiresIn,
        mid: targetMid,
        content: content);
    final message = ChatMsg(
        target: MsgTargetUser(uid).toJson(),
        mid: fakeMid,
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());
    ChatMsgM chatMsgM = ChatMsgM.fromReply(message, localMid, MsgStatus.fail);

    await chatMsgDao.add(chatMsgM).then((_) async {
      final toBeFired = ChatMsgM.fromMsg(message, localMid, MsgStatus.sending);
      App.app.chatService.fireMsg(toBeFired, true);

      await MessageApi().reply(targetMid, content, detail.properties).then(
        (response) async {
          if (response.statusCode == 200) {
            final mid = response.data!;
            message.mid = mid;
            chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.success);
            await chatMsgDao.update(chatMsgM).then((value) {
              App.app.chatService.fireMsg(chatMsgM, true);
            }).onError((error, stackTrace) {
              App.logger.severe(error);
              App.app.chatService
                  .fireMsg(chatMsgM..status = MsgStatus.fail, true);
            });
          } else {
            App.logger.severe(
                "Reply message send failed, statusCode: ${response.statusCode}");
            App.app.chatService
                .fireMsg(chatMsgM..status = MsgStatus.fail, true);
          }
        },
      ).onError((error, stackTrace) {
        App.logger.severe(error);
        App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
      });
    });
  }

  Future<void> sendUserFile(int uid, String path,
      {void Function(double progress)? progress,
      String? resendLocalMid}) async {
    final localMid = resendLocalMid ?? uuid();
    final fakeMid = await _getFakeMid();
    final expiresIn =
        (await UserInfoDao().getUserByUid(uid))?.properties.burnAfterReadSecond;

    final chatMsgDao = ChatMsgDao();

    String contentType = lookupMimeType(path) ?? "";
    String filename = p.basename(path);
    File file = File(path);
    int size = await file.length();

    final isImage = contentType.startsWith("image");
    final isGif = contentType == "image/gif";

    Map<String, dynamic> properties = {
      "cid": localMid,
      "content_type": contentType,
      'name': filename,
      'size': size
    };

    final chatId = SharedFuncs.getChatId(uid: uid)!;
    final fileBytes = await file.readAsBytes();
    Uint8List uploadBytes = fileBytes;

    if (isImage) {
      final decodedImage = await decodeImageFromList(await file.readAsBytes());
      properties
          .addAll({'height': decodedImage.height, 'width': decodedImage.width});

      // Save image to local storage first. The [ChatPageController] will have
      // an image file to prepare for [tileData].
      // Only save compressed image for normal image;
      // Save original image for gif.

      if (isGif) {
        // TODO: change to save File instead of bytes.
        await FileHandler.singleton
            .saveImageNormal(chatId, fileBytes, localMid, filename);
      } else {
        // TODO: change to save File instead of bytes.
        final thumbBytes =
            await FlutterImageCompress.compressWithList(fileBytes, quality: 25);
        uploadBytes = thumbBytes;
        await FileHandler.singleton
            .saveImageThumb(chatId, thumbBytes, localMid, filename);
      }
    } else {
      // TODO: change to save File instead of bytes.
      await FileHandler.singleton
          .saveFile(chatId, fileBytes, localMid, filename);
    }

    final detail = MsgNormal(
        properties: properties,
        contentType: typeFile,
        expiresIn: expiresIn,
        content: filename);

    ChatMsg message = ChatMsg(
        target: MsgTargetUser(uid).toJson(),
        mid: fakeMid,
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());

    ChatMsgM chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.fail);
    await chatMsgDao.add(chatMsgM).then((_) async {
      final toBeFired = ChatMsgM.fromMsg(message, localMid, MsgStatus.sending);
      App.app.chatService.fireMsg(toBeFired, true);
    });

    ValueNotifier<double> progress0 = ValueNotifier(0);
    final task = SendTask(
      localMid: localMid,
      sendTask: () => _uploadAndSendFile(
          contentType, filename, uploadBytes, chatMsgM, (progress) {
        progress0.value = progress;
      }),
    );
    task.progress = progress0;
    SendTaskQueue.singleton.addTask(task);
  }

  /// Send audio file and message to server, then to a user.
  ///
  /// [localMid] is provided in [VoiceButton] already, as the [localMid] has been
  /// generated when the audio file is created.
  Future<void> sendUserAudio(int uid, String localMid, File file,
      {void Function(double progress)? progress}) async {
    final fakeMid = await _getFakeMid();
    final expiresIn =
        (await UserInfoDao().getUserByUid(uid))?.properties.burnAfterReadSecond;

    final chatMsgDao = ChatMsgDao();

    final path = file.path;

    String contentType = lookupMimeType(path) ?? "";
    String filename = p.basename(path);
    Uint8List fileBytes = await file.readAsBytes();
    int size = await file.length();

    Map<String, dynamic> properties = {
      "cid": localMid,
      "content_type": contentType,
      'name': filename,
      'size': size
    };

    final detail = MsgNormal(
        properties: properties,
        contentType: typeAudio,
        expiresIn: expiresIn,
        content: filename);

    ChatMsg message = ChatMsg(
        target: MsgTargetUser(uid).toJson(),
        mid: fakeMid,
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());

    ChatMsgM chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.fail);

    await chatMsgDao.add(chatMsgM).then((_) async {
      final toBeFired = ChatMsgM.fromMsg(message, localMid, MsgStatus.sending);
      App.app.chatService.fireMsg(toBeFired, true);
    });

    ValueNotifier<double> progress0 = ValueNotifier(0);
    final task = SendTask(
      localMid: localMid,
      sendTask: () => _uploadAndSendAudio(
          contentType, filename, fileBytes, chatMsgM, (progress) {
        progress0.value = progress;
      }),
    );
    task.progress = progress0;
    SendTaskQueue.singleton.addTask(task);
  }

  Future<void> sendChannelText(int gid, String content,
      {String? resendLocalMid}) async {
    final expiresIn = (await GroupInfoDao().getGroupByGid(gid))
        ?.properties
        .burnAfterReadSecond;
    final regex = RegExp(r'\s@[0-9]+\s');
    List<int> mentions = [];
    for (var each in regex.allMatches(content)) {
      try {
        final uid =
            int.parse(content.substring(each.start, each.end).substring(2));
        mentions.add(uid);
      } catch (e) {
        App.logger.severe(e);
      }
    }

    final fakeMid = await _getFakeMid();
    final localMid = resendLocalMid ?? uuid();

    final chatMsgDao = ChatMsgDao();

    final detail = MsgNormal(
        properties: {"cid": localMid, 'mentions': mentions},
        contentType: typeText,
        expiresIn: expiresIn,
        content: content);
    final message = ChatMsg(
        target: MsgTargetGroup(gid).toJson(),
        mid: fakeMid,
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());
    ChatMsgM chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.fail);

    await chatMsgDao.add(chatMsgM).then((_) async {
      final toBeFired = ChatMsgM.fromMsg(message, localMid, MsgStatus.sending);
      App.app.chatService.fireMsg(toBeFired, true);

      await GroupApi().sendTextMsg(gid, content, detail.properties).then(
        (response) async {
          if (response.statusCode == 200) {
            final mid = response.data!;
            message.mid = mid;
            chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.success);
            await chatMsgDao.update(chatMsgM).then((value) {
              App.app.chatService.fireMsg(chatMsgM, true);
            }).onError((error, stackTrace) {
              App.logger.severe(error);
              App.app.chatService
                  .fireMsg(chatMsgM..status = MsgStatus.fail, true);
            });
          } else {
            App.logger.severe(
                "Message send failed, statusCode: ${response.statusCode}");
            App.app.chatService
                .fireMsg(chatMsgM..status = MsgStatus.fail, true);
          }
        },
      ).onError((error, stackTrace) {
        App.logger.severe(error);
        App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
      });
    });
  }

  Future<void> sendChannelReply(int gid, int targetMid, String content,
      {String? resendLocalMid}) async {
    final expiresIn = (await GroupInfoDao().getGroupByGid(gid))
        ?.properties
        .burnAfterReadSecond;

    final regex = RegExp(r'\s@[0-9]+\s');
    List<int> mentions = [];
    for (var each in regex.allMatches(content)) {
      try {
        final uid =
            int.parse(content.substring(each.start, each.end).substring(2));
        mentions.add(uid);
      } catch (e) {
        App.logger.severe(e);
      }
    }

    final fakeMid = await _getFakeMid();
    final localMid = resendLocalMid ?? uuid();

    final chatMsgDao = ChatMsgDao();

    final detail = MsgReply(
        properties: {"cid": localMid, 'mentions': mentions},
        contentType: typeText,
        expiresIn: expiresIn,
        mid: targetMid,
        content: content);
    final message = ChatMsg(
        target: MsgTargetGroup(gid).toJson(),
        mid: fakeMid,
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());
    ChatMsgM chatMsgM = ChatMsgM.fromReply(message, localMid, MsgStatus.fail);

    await chatMsgDao.add(chatMsgM).then((_) async {
      final toBeFired = ChatMsgM.fromMsg(message, localMid, MsgStatus.sending);
      App.app.chatService.fireMsg(toBeFired, true);

      await MessageApi().reply(targetMid, content, detail.properties).then(
        (response) async {
          if (response.statusCode == 200) {
            final mid = response.data!;
            message.mid = mid;
            chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.success);
            await chatMsgDao.update(chatMsgM).then((value) {
              App.app.chatService.fireMsg(chatMsgM, true);
            }).onError((error, stackTrace) {
              App.logger.severe(error);
              App.app.chatService
                  .fireMsg(chatMsgM..status = MsgStatus.fail, true);
            });
          } else {
            App.logger.severe(
                "Reply message send failed, statusCode: ${response.statusCode}");
            App.app.chatService
                .fireMsg(chatMsgM..status = MsgStatus.fail, true);
          }
        },
      ).onError((error, stackTrace) {
        App.logger.severe(error);
        App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
      });
    });
  }

  Future<void> sendChannelFile(int gid, String path,
      {void Function(double progress)? progress,
      String? resendLocalMid}) async {
    final localMid = resendLocalMid ?? uuid();
    final fakeMid = await _getFakeMid();
    final expiresIn = (await GroupInfoDao().getGroupByGid(gid))
        ?.properties
        .burnAfterReadSecond;

    final chatMsgDao = ChatMsgDao();

    String contentType = lookupMimeType(path) ?? "";
    String filename = p.basename(path);
    File file = File(path);
    int size = await file.length();

    final isImage = contentType.startsWith("image");
    final isGif = contentType == "image/gif";

    final chatId = SharedFuncs.getChatId(gid: gid)!;
    final fileBytes = await file.readAsBytes();
    Uint8List uploadBytes = fileBytes;

    Map<String, dynamic> properties = {
      "cid": localMid,
      "content_type": contentType,
      'name': filename,
      'size': size
    };

    if (isImage) {
      final decodedImage = await decodeImageFromList(await file.readAsBytes());
      properties
          .addAll({'height': decodedImage.height, 'width': decodedImage.width});

      // Save image to local storage first. The [ChatPageController] will have
      // an image file to prepare for [tileData].
      // Only save compressed image for normal image;
      // Save original image for gif.

      if (isGif) {
        print("isGif");
        // TODO: change to save File instead of bytes.
        await FileHandler.singleton
            .saveImageNormal(chatId, fileBytes, localMid, filename);
      } else {
        // TODO: change to save File instead of bytes.
        final thumbBytes =
            await FlutterImageCompress.compressWithList(fileBytes, quality: 25);
        uploadBytes = thumbBytes;
        await FileHandler.singleton
            .saveImageThumb(chatId, thumbBytes, localMid, filename);
      }
    } else {
      // TODO: change to save File instead of bytes.
      await FileHandler.singleton
          .saveFile(chatId, fileBytes, localMid, filename);
    }

    final detail = MsgNormal(
        properties: properties,
        contentType: typeFile,
        expiresIn: expiresIn,
        content: filename);

    ChatMsg message = ChatMsg(
        target: MsgTargetGroup(gid).toJson(),
        mid: fakeMid,
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());

    ChatMsgM chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.fail);
    await chatMsgDao.add(chatMsgM).then((_) async {
      final toBeFired = ChatMsgM.fromMsg(message, localMid, MsgStatus.sending);
      App.app.chatService.fireMsg(toBeFired, true);
    });

    ValueNotifier<double> progress0 = ValueNotifier(0);
    final task = SendTask(
      localMid: localMid,
      sendTask: () => _uploadAndSendFile(
          contentType, filename, uploadBytes, chatMsgM, (progress) {
        progress0.value = progress;
      }),
    );
    task.progress = progress0;
    SendTaskQueue.singleton.addTask(task);
  }

  /// Send audio file and message to server, then to a channel.
  ///
  /// [localMid] is provided in [VoiceButton] already, as the [localMid] has been
  /// generated when the audio file is created.
  Future<void> sendChannelAudio(int gid, String localMid, File file,
      {void Function(double progress)? progress}) async {
    final fakeMid = await _getFakeMid();
    final expiresIn = (await GroupInfoDao().getGroupByGid(gid))
        ?.properties
        .burnAfterReadSecond;

    final chatMsgDao = ChatMsgDao();

    final path = file.path;

    String contentType = lookupMimeType(path) ?? "";
    String filename = p.basename(path);
    Uint8List fileBytes = await file.readAsBytes();
    int size = await file.length();

    Map<String, dynamic> properties = {
      "cid": localMid,
      "content_type": contentType,
      'name': filename,
      'size': size
    };

    final detail = MsgNormal(
        properties: properties,
        contentType: typeAudio,
        expiresIn: expiresIn,
        content: filename);

    ChatMsg message = ChatMsg(
        target: MsgTargetGroup(gid).toJson(),
        mid: fakeMid,
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());

    ChatMsgM chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgStatus.fail);
    await chatMsgDao.add(chatMsgM).then((_) async {
      final toBeFired = ChatMsgM.fromMsg(message, localMid, MsgStatus.sending);
      App.app.chatService.fireMsg(toBeFired, true);
    });

    ValueNotifier<double> progress0 = ValueNotifier(0);
    final task = SendTask(
      localMid: localMid,
      sendTask: () => _uploadAndSendAudio(
          contentType, filename, fileBytes, chatMsgM, (progress) {
        progress0.value = progress;
      }),
    );
    task.progress = progress0;
    SendTaskQueue.singleton.addTask(task);
  }

  /// Upload and send file.
  ///
  /// Return a bool showing whether the upload and send is successful or not.
  Future<bool> _uploadAndSendFile(
      String contentType,
      String filename,
      // File file,
      Uint8List fileBytes,
      ChatMsgM chatMsgM,
      void Function(double progress)? progress) async {
    // Prepare
    final prepareReq =
        FilePrepareRequest(contentType: contentType, filename: filename);
    String fileId;

    try {
      final resourceApi = ResourceApi();
      fileId = (await resourceApi.prepareFile(prepareReq)).data!;
    } catch (e) {
      App.logger.severe(e);
      App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
      return false;
    }

    // Upload
    // final fileBytes = await file.readAsBytes();
    final fileUploader = FileUploader(
        fileBytes: fileBytes, fileId: fileId, onUploadProgress: progress);

    FileUploadResponse uploadRes;
    try {
      uploadRes = (await fileUploader.upload(contentType))!.data!;
    } catch (e) {
      App.logger.severe(e);
      App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);

      return false;
    }

    // Send
    Response<int> res;

    try {
      if (chatMsgM.isGroupMsg) {
        final groupApi = GroupApi();
        res = await groupApi.sendFileMsg(
            chatMsgM.gid, chatMsgM.localMid, uploadRes.path,
            width: chatMsgM.msgNormal?.properties?["width"],
            height: chatMsgM.msgNormal?.properties?["height"]);
      } else {
        final userApi = UserApi();
        res = await userApi.sendFileMsg(
            chatMsgM.dmUid, chatMsgM.localMid, uploadRes.path,
            width: chatMsgM.msgNormal?.properties?["width"],
            height: chatMsgM.msgNormal?.properties?["height"]);
      }

      if (res.statusCode == 200 && res.data != null) {
        final mid = res.data!;
        chatMsgM.mid = mid;
        chatMsgM.status = MsgStatus.success;
        await ChatMsgDao().add(chatMsgM).then((chatMsgM) async {
          App.app.chatService
              .fireMsg(chatMsgM..status = MsgStatus.success, true);
        });
        return true;
      } else {
        App.logger.severe(res.statusCode);
        App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
        return false;
      }
    } catch (e) {
      App.logger.severe(e);
      App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
      return false;
    }
  }

  /// Upload and send audio file.
  ///
  /// Return a bool showing whether the upload and send is successful or not.
  Future<bool> _uploadAndSendAudio(
      String contentType,
      String filename,
      // File file,
      Uint8List fileBytes,
      ChatMsgM chatMsgM,
      void Function(double progress)? progress) async {
    // Prepare
    final prepareReq =
        FilePrepareRequest(contentType: contentType, filename: filename);
    String fileId;

    try {
      final resourceApi = ResourceApi();
      fileId = (await resourceApi.prepareFile(prepareReq)).data!;
    } catch (e) {
      App.logger.severe(e);
      App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
      return false;
    }

    // Upload
    // final fileBytes = await file.readAsBytes();
    final fileUploader = FileUploader(
        fileBytes: fileBytes, fileId: fileId, onUploadProgress: progress);

    FileUploadResponse uploadRes;
    try {
      uploadRes = (await fileUploader.upload(contentType))!.data!;
    } catch (e) {
      App.logger.severe(e);
      App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
      return false;
    }

    // Send
    Response<int> res;

    try {
      if (chatMsgM.isGroupMsg) {
        final groupApi = GroupApi();
        res = await groupApi.sendAudioMsg(
            chatMsgM.gid, chatMsgM.localMid, uploadRes.path);
      } else {
        final userApi = UserApi();
        res = await userApi.sendAudioMsg(
            chatMsgM.dmUid, chatMsgM.localMid, uploadRes.path);
      }

      if (res.statusCode == 200 && res.data != null) {
        final mid = res.data!;
        chatMsgM.mid = mid;
        chatMsgM.status = MsgStatus.success;
        await ChatMsgDao().add(chatMsgM).then((chatMsgM) async {
          App.app.chatService
              .fireMsg(chatMsgM..status = MsgStatus.success, true);
        });
        return true;
      } else {
        App.logger.severe(res.statusCode);
        App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
        return false;
      }
    } catch (e) {
      App.logger.severe(e);
      App.app.chatService.fireMsg(chatMsgM..status = MsgStatus.fail, true);
      return false;
    }
  }

  Future<void> sendEdit(int targetMid, String content) async {
    final targetMsgM = await ChatMsgDao().getMsgByMid(targetMid);
    if (targetMsgM == null) {
      return;
    }

    // Fire status to UI message list, but only change db after server responses.
    App.app.chatService.fireMsg(targetMsgM..status = MsgStatus.sending, true);

    // Send to server.
    MessageApi api = MessageApi();
    try {
      await api.edit(targetMid, content).then((response) async {
        if (response.statusCode == 200) {
          // Do nothing, edits and reactions purly depend on SSE events.
        } else {
          App.logger.severe(response.statusCode);
          App.app.chatService.fireMsg(targetMsgM, true);
        }
      });
    } catch (e) {
      App.logger.severe(e);
      App.app.chatService.fireMsg(targetMsgM, true);
    }
  }

  Future<bool> sendReaction(ChatMsgM targetMsgM, String reaction) async {
    App.app.chatService.fireMsg(targetMsgM..status = MsgStatus.sending, true);
    bool succeed = false;

    try {
      final messageApi = MessageApi();
      await messageApi.react(targetMsgM.mid, reaction).then((response) {
        if (response.statusCode == 200) {
          succeed = true;
        } else {}
      });
    } catch (e) {
      App.logger.severe(e);
    }

    if (succeed) {
      return true;
    } else {
      // fail. SSE won't push any new message. So we need to roll back the
      // message status.
      final rollbackMsgM = targetMsgM..status = MsgStatus.success;
      App.app.chatService.fireMsg(rollbackMsgM, true);
      return false;
    }
  }

  Future<void> resend(ChatMsgM chatMsgM) async {
    if (chatMsgM.isGroupMsg) {
      if (chatMsgM.detailContentType == MsgContentType.text) {
        final content =
            chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content ?? '';
        await sendChannelText(chatMsgM.gid, content,
            resendLocalMid: chatMsgM.localMid);
      } else if (chatMsgM.detailContentType == MsgContentType.file) {
        final file = await FileHandler.singleton.getLocalFile(chatMsgM);
        await sendChannelFile(chatMsgM.gid, file?.path ?? "");
      }
    } else {}
  }

  Future<int> _getFakeMid() async {
    return -1;
  }
}
