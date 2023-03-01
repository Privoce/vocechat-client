import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:vocechat_client/extensions.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:path/path.dart' as p;
import 'package:vocechat_client/dao/init_dao/group_info.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/services/chat_service.dart';
import 'package:vocechat_client/services/file_handler.dart';
import 'package:vocechat_client/services/file_uploader.dart';
import 'package:vocechat_client/services/send_task_queue/send_task_queue.dart';
import 'package:vocechat_client/shared_funcs.dart';

typedef MessageSendFunction = Future<bool> Function(
    String localMid, String msg, SendType type,
    {int? gid, ChatMsgM? relatedMsgM, int? uid});

class SendService {
  SendService();

  SendService._singleton();
  static final SendService singleton = SendService._singleton();

  void sendMessage(String localMid, String msg, SendType type,
      {int? gid, int? uid, int? targetMid, Uint8List? blob}) async {
    switch (type) {
      case SendType.normal:
        SendText().sendMessage(localMid, msg, type,
            gid: gid, uid: uid, targetMid: targetMid);
        break;
      case SendType.edit:
        SendEdit().sendMessage(localMid, msg, type,
            gid: gid, uid: uid, targetMid: targetMid);
        break;
      case SendType.reply:
        SendReply().sendMessage(localMid, msg, type,
            gid: gid, uid: uid, targetMid: targetMid);
        break;
      case SendType.file:
        SendFile().sendMessage(localMid, msg, type,
            gid: gid, uid: uid, targetMid: targetMid, blob: blob);
        break;
      default:
        SendText().sendMessage(localMid, msg, type,
            gid: gid, uid: uid, targetMid: targetMid);
    }
  }
}

abstract class AbstractSend {
  Future<bool> sendMessage(String localMid, String msg, SendType type,
      {int? gid,
      int? uid,
      int? targetMid,
      Uint8List? blob,
      void Function(double progress)? progress});

  static Future<int> getFakeMid() async {
    final maxMid = await ChatMsgDao().getMaxMid();
    final awaitingTaskCount = SendTaskQueue.singleton.length;
    return maxMid + awaitingTaskCount + 1;
  }
}

class SendText implements AbstractSend {
  @override
  Future<bool> sendMessage(String localMid, String msg, SendType type,
      {int? gid,
      int? uid,
      int? targetMid,
      Uint8List? blob,
      void Function(double progress)? progress}) async {
    if (gid != null && gid != -1) {
      return _sendGroupText(msg, gid, localMid);
    } else if (uid != null && uid != -1) {
      return _sendUserText(msg, uid, localMid);
    }
    return false;
  }

  Future<bool> _sendGroupText(String msg, int gid, String localMid) async {
    final regex = RegExp(r'\s@[0-9]+\s');
    List<int> mentions = [];
    for (var each in regex.allMatches(msg)) {
      try {
        final uid = int.parse(msg.substring(each.start, each.end).substring(2));
        mentions.add(uid);
      } catch (e) {
        App.logger.severe(e);
      }
    }

    final expiresIn = (await GroupInfoDao().getGroupByGid(gid))
        ?.properties
        .burnAfterReadSecond;

    final detail = MsgNormal(
        properties: {"cid": localMid, 'mentions': mentions},
        contentType: typeText,
        expiresIn: expiresIn,
        content: msg);
    ChatMsg message = ChatMsg(
        target: MsgTargetGroup(gid).toJson(),
        mid: await AbstractSend.getFakeMid(),
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());
    ChatMsgM chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);

    // Update local database and UI
    // Database execution happens first to ensure index and [msgCount] in
    // ChatPage, which is read from database, are correct.
    final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.sending);
    App.app.chatService.mainTaskQueue
        .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
              App.app.chatService.fireMsg(msgM, localMid, null);
              App.app.chatService.fireSnippet(msgM);
            }));

    // Send to server.
    return _apiSendGroupText(message, localMid, gid, msg, detail.properties);
  }

  Future<bool> _apiSendGroupText(ChatMsg message, String localMid, int gid,
      String msg, Map<String, dynamic>? properties) async {
    GroupApi api = GroupApi();
    try {
      final res = await api.sendTextMsg(gid, msg, properties);
      if (res.statusCode == 200 && res.data != null) {
        final mid = res.data!;

        message.mid = mid;
        final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.success);
        App.app.chatService.mainTaskQueue
            .add(() => ChatMsgDao().addOrUpdate(msgM).then((value) {
                  App.app.chatService.fireMsg(msgM, localMid, null);
                  App.app.chatService.fireSnippet(msgM);
                }));

        return true;
      } else {
        App.logger.severe(res.statusCode);
        final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
        App.app.chatService.fireMsg(msgM, localMid, null);
        App.app.chatService.fireSnippet(msgM);
      }
    } catch (e) {
      App.logger.severe(e);
      final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
      App.app.chatService.fireMsg(msgM, localMid, null);
      App.app.chatService.fireSnippet(msgM);
    }
    return false;
  }

  Future<bool> _sendUserText(String msg, int uid, String localMid) async {
    final expiresIn =
        (await UserInfoDao().getUserByUid(uid))?.properties.burnAfterReadSecond;

    final detail = MsgNormal(
        properties: {"cid": localMid},
        contentType: typeText,
        expiresIn: expiresIn,
        content: msg);
    final message = ChatMsg(
        target: MsgTargetUser(uid).toJson(),
        mid: await AbstractSend.getFakeMid(),
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());
    ChatMsgM chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);

    // Update local database and UI
    App.app.chatService.mainTaskQueue
        .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
              final msgM =
                  ChatMsgM.fromMsg(message, localMid, MsgSendStatus.sending);
              App.app.chatService.fireMsg(msgM, localMid, null);
              App.app.chatService.fireSnippet(msgM);
            }));

    // Send to server.
    return _apiSendUserText(message, localMid, uid, msg, detail.properties);
  }

  Future<bool> _apiSendUserText(ChatMsg message, String localMid, int uid,
      String msg, Map<String, dynamic>? properties) async {
    // Send to server.
    UserApi api = UserApi();
    try {
      final res = await api.sendTextMsg(uid, msg, localMid);
      if (res.statusCode == 200 && res.data != null) {
        final mid = res.data!;

        message.mid = mid;
        final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.success);
        App.app.chatService.mainTaskQueue
            .add(() => ChatMsgDao().addOrUpdate(msgM).then((value) {
                  App.app.chatService.fireMsg(msgM, localMid, null);
                  App.app.chatService.fireSnippet(msgM);
                }));

        return true;
      } else {
        App.logger.severe(res.statusCode);
        final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
        App.app.chatService.fireMsg(msgM, localMid, null);
        App.app.chatService.fireSnippet(msgM);
      }
    } catch (e) {
      App.logger.severe(e);
      final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
      App.app.chatService.fireMsg(msgM, localMid, null);
      App.app.chatService.fireSnippet(msgM);
    }
    return false;
  }
}

class SendEdit implements AbstractSend {
  @override
  Future<bool> sendMessage(String localMid, String msg, SendType type,
      {int? gid,
      int? uid,
      int? targetMid,
      Uint8List? blob,
      void Function(double progress)? progress}) async {
    assert(targetMid != null);

    // Update local database and UI
    ChatMsgM? msgM =
        await ChatMsgDao().editMsgByMid(targetMid!, msg, MsgSendStatus.fail);
    if (msgM == null) return false;

    msgM.status = MsgSendStatus.sending.name;
    App.app.chatService.fireMsg(msgM, localMid, null);
    App.app.chatService.fireReaction(ReactionTypes.edit, targetMid, msgM);

    // Send to server.
    MessageApi api = MessageApi();
    try {
      final res = await api.edit(targetMid, msg);
      if (res.statusCode == 200 && res.data != null) {
        await ChatMsgDao()
            .editMsgByMid(targetMid, msg, MsgSendStatus.success)
            .then((value) {
          if (value != null) {
            App.app.chatService.fireMsg(value, localMid, null);
            App.app.chatService
                .fireReaction(ReactionTypes.edit, targetMid, value);
          }
        });

        return true;
      } else {
        App.logger.severe(res.statusCode);
        msgM.status = MsgSendStatus.fail.name;
        App.app.chatService.fireMsg(msgM, localMid, null);
        App.app.chatService.fireReaction(ReactionTypes.edit, targetMid, msgM);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    msgM.status = MsgSendStatus.fail.name;
    App.app.chatService.fireMsg(msgM, localMid, null);
    App.app.chatService.fireReaction(ReactionTypes.edit, targetMid, msgM);

    return false;
  }
}

class SendReply implements AbstractSend {
  @override
  Future<bool> sendMessage(String localMid, String msg, SendType type,
      {int? gid,
      int? uid,
      int? targetMid,
      Uint8List? blob,
      void Function(double progress)? progress}) async {
    assert(targetMid != null);

    if (gid != null && gid != -1) {
      return _sendGroupReply(msg, gid, targetMid!, localMid);
    } else if (uid != null && uid != -1) {
      return _sendUserReply(msg, uid, targetMid!, localMid);
    }
    return false;
  }

  Future<bool> _sendGroupReply(
      String msg, int gid, int targetMid, String localMid) async {
    final regex = RegExp(r'\s@[0-9]+\s');
    List<int> mentions = [];
    for (var each in regex.allMatches(msg)) {
      try {
        final uid = int.parse(msg.substring(each.start, each.end).substring(2));
        mentions.add(uid);
      } catch (e) {
        App.logger.severe(e);
      }
    }
    final detail = MsgReply(
        mid: targetMid,
        contentType: typeText,
        content: msg,
        properties: {"cid": localMid, 'mentions': mentions});

    final message = ChatMsg(
        mid: await AbstractSend.getFakeMid(),
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        target: MsgTargetGroup(gid).toJson(),
        detail: detail.toJson());

    ChatMsgM chatMsgM =
        ChatMsgM.fromReply(message, localMid, MsgSendStatus.fail);

    // Update local database and UI
    final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.sending);
    App.app.chatService.mainTaskQueue
        .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
              App.app.chatService.fireMsg(msgM, localMid, null);
              App.app.chatService.fireSnippet(msgM);
            }));

    // Send to server.
    MessageApi api = MessageApi();
    try {
      final res = await api.reply(targetMid, msg, detail.properties);
      if (res.statusCode == 200 && res.data != null) {
        final mid = res.data!;

        message.mid = mid;
        chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.success);
        App.app.chatService.mainTaskQueue
            .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
                  App.app.chatService.fireMsg(chatMsgM, localMid, null);
                  App.app.chatService.fireSnippet(chatMsgM);
                }));
        return true;
      } else {
        App.logger.severe(res.statusCode);
        final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
        App.app.chatService.fireMsg(msgM, localMid, null);
        App.app.chatService.fireSnippet(msgM);
      }
    } catch (e) {
      App.logger.severe(e);
      final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
      App.app.chatService.fireMsg(msgM, localMid, null);
      App.app.chatService.fireSnippet(msgM);
    }

    return false;
  }

  Future<bool> _sendUserReply(
      String msg, int uid, int targetMid, String localMid) async {
    final detail = MsgReply(
        properties: {"cid": localMid},
        contentType: typeText,
        content: msg,
        mid: targetMid);
    final message = ChatMsg(
        target: MsgTargetUser(uid).toJson(),
        mid: await AbstractSend.getFakeMid(),
        fromUid: App.app.userDb!.uid,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        detail: detail.toJson());
    ChatMsgM chatMsgM =
        ChatMsgM.fromReply(message, localMid, MsgSendStatus.fail);

    // Update local database and UI
    final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.sending);

    App.app.chatService.mainTaskQueue
        .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
              App.app.chatService.fireMsg(msgM, localMid, null);
              App.app.chatService.fireSnippet(msgM);
            }));

    // Send to server.
    MessageApi api = MessageApi();
    try {
      final res = await api.reply(targetMid, msg, detail.properties);
      if (res.statusCode == 200 && res.data != null) {
        final mid = res.data!;

        message.mid = mid;
        chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.success);
        App.app.chatService.mainTaskQueue
            .add(() => ChatMsgDao().addOrUpdate(chatMsgM).then((value) {
                  App.app.chatService.fireMsg(chatMsgM, localMid, null);
                  App.app.chatService.fireSnippet(chatMsgM);
                }));
        return true;
      } else {
        App.logger.severe(res.statusCode);
        final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
        App.app.chatService.fireMsg(msgM, localMid, null);
        App.app.chatService.fireSnippet(msgM);
      }
    } catch (e) {
      App.logger.severe(e);
      final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
      App.app.chatService.fireMsg(msgM, localMid, null);
      App.app.chatService.fireSnippet(msgM);
    }

    return false;
  }
}

class SendFile implements AbstractSend {
  @override
  Future<bool> sendMessage(String localMid, String path, SendType type,
      {int? gid,
      int? uid,
      int? targetMid,
      Uint8List? blob,
      void Function(double progress)? progress}) async {
    List<int> headerBytes;
    String contentType;
    String filename;
    File file;
    int size;
    if (blob != null && blob.isNotEmpty) {
      contentType = lookupMimeType("", headerBytes: blob) ?? "image/jpg";
      filename = "image.jpg";
      final tempPath = (await getTemporaryDirectory()).path + "/$filename";
      file = File(tempPath);
      await file.writeAsBytes(blob);
      size = file.lengthSync();
    } else {
      headerBytes = _getHeaderBytesFromPath(path);
      contentType = lookupMimeType(path, headerBytes: headerBytes) ?? "";
      filename = p.basename(path);
      file = File(path);
      size = file.lengthSync();
    }

    final isImage = contentType.startsWith("image/");

    Map<String, dynamic> properties = {
      "cid": localMid,
      "content_type": contentType,
      'name': filename,
      'size': size
    };

    if (isImage) {
      final decodedImage = await decodeImageFromList(file.readAsBytesSync());
      properties
          .addAll({'height': decodedImage.height, 'width': decodedImage.width});
    }

    ChatMsg message;
    if (gid != null && gid != -1) {
      final expiresIn = (await GroupInfoDao().getGroupByGid(gid))
          ?.properties
          .burnAfterReadSecond;
      final detail = MsgNormal(
          properties: properties,
          contentType: typeFile,
          expiresIn: expiresIn,
          content: filename);

      message = ChatMsg(
          target: MsgTargetGroup(gid).toJson(),
          mid: await AbstractSend.getFakeMid(),
          fromUid: App.app.userDb!.uid,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          detail: detail.toJson());
    } else {
      final expiresIn = (await UserInfoDao().getUserByUid(uid!))
          ?.properties
          .burnAfterReadSecond;
      final detail = MsgNormal(
          properties: properties,
          contentType: typeFile,
          expiresIn: expiresIn,
          content: filename);

      message = ChatMsg(
          target: MsgTargetUser(uid).toJson(),
          mid: await AbstractSend.getFakeMid(),
          fromUid: App.app.userDb!.uid,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          detail: detail.toJson());
    }

    ChatMsgM chatMsgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
    App.app.chatService.mainTaskQueue
        .add(() => ChatMsgDao().addOrUpdate(chatMsgM));

    Uint8List fileBytes = file.readAsBytesSync();

    // Put task into sending queue first to avoid empty sending status in
    // chat page
    ValueNotifier<double> _progress = ValueNotifier(0);
    final task = SendTask(
        localMid: localMid,
        sendTask: () => _apiSendFile(contentType, filename, message, chatMsgM,
                fileBytes, localMid, file, uid, gid, (progress) {
              _progress.value = progress;
            }));
    task.progress = _progress;
    SendTaskQueue.singleton.addTask(task);

    // Compress and save thumb if is image.
    if (isImage) {
      final chatId = SharedFuncs.getChatId(gid: gid, uid: uid);
      Uint8List thumbBytes =
          await FlutterImageCompress.compressWithList(fileBytes, quality: 25);

      // Save both thumb and original image to local document storage.
      final thumbFile = await FileHandler.singleton
          .saveImageThumb(chatId!, thumbBytes, localMid, filename);

      final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.sending);
      App.app.chatService.fireMsg(msgM, localMid, thumbFile);
      App.app.chatService.fireSnippet(msgM);

      await FileHandler.singleton
          .saveImageNormal(chatId, fileBytes, localMid, filename);
      fileBytes = thumbBytes;
      file = thumbFile!;
    } else {
      final chatId = SharedFuncs.getChatId(gid: gid, uid: uid);
      file = (await FileHandler.singleton
          .saveFile(chatId!, fileBytes, localMid, filename))!;

      chatMsgM.status = MsgSendStatus.sending.name;
      App.app.chatService.fireMsg(chatMsgM, localMid, file);
      App.app.chatService.fireSnippet(chatMsgM);
    }

    return true;
  }

  Future<bool> _apiSendFile(
      String contentType,
      String filename,
      ChatMsg message,
      ChatMsgM chatMsgM,
      Uint8List fileBytes,
      String localMid,
      File file,
      int? uid,
      int? gid,
      void Function(double progress)? progress) async {
    // prepare
    final prepareReq =
        FilePrepareRequest(contentType: contentType, filename: filename);
    String fileId;

    try {
      final resourceApi = ResourceApi();
      fileId = (await resourceApi.prepareFile(prepareReq)).data!;
    } catch (e) {
      App.logger.severe(e);
      final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
      App.app.chatService.fireMsg(msgM, localMid, file);
      App.app.chatService.fireSnippet(msgM);
      return false;
    }

    // upload
    final fileUploader = FileUploader(
        fileBytes: fileBytes, fileId: fileId, onUploadProgress: progress);
    FileUploadResponse uploadRes;
    try {
      uploadRes = (await fileUploader.upload(contentType))!.data!;
    } catch (e) {
      App.logger.severe(e);
      final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
      App.app.chatService.fireMsg(msgM, localMid, file);
      App.app.chatService.fireSnippet(msgM);
      return false;
    }

    // send
    try {
      Response<int> res;

      if (gid != null && gid != -1) {
        final groupApi = GroupApi();
        res = await groupApi.sendFileMsg(gid, localMid, uploadRes.path,
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
        message.mid = res.data!;
        final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.success);
        if (await ChatMsgDao()
            .updateMsgStatusByLocalMid(msgM, MsgSendStatus.success)) {
          SendTaskQueue.singleton.removeTaskByLocalMid(localMid);
          App.app.chatService.fireSnippet(msgM);
          App.app.chatService.fireMsg(msgM, localMid, file);
          return true;
        }
      } else {
        App.logger.severe(res.statusCode);
        final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
        SendTaskQueue.singleton.removeTaskByLocalMid(localMid);
        App.app.chatService.fireMsg(msgM, localMid, file);
        App.app.chatService.fireSnippet(msgM);
      }
    } catch (e) {
      App.logger.severe(e);
      final msgM = ChatMsgM.fromMsg(message, localMid, MsgSendStatus.fail);
      SendTaskQueue.singleton.removeTaskByLocalMid(localMid);
      App.app.chatService.fireMsg(msgM, localMid, file);
      App.app.chatService.fireSnippet(msgM);
      return false;
    }

    SendTaskQueue.singleton.removeTaskByLocalMid(localMid);
    return true;
  }

  List<int> _getHeaderBytesFromPath(String path) {
    List<int> fileBytes = File(path).readAsBytesSync().toList();
    List<int> header = [];

    for (var element in fileBytes) {
      if (element == 0) return [];
      header.add(element);
    }
    return header;
  }

  List<int> _getHeaderBytesFromBytes(Uint8List bytes) {
    List<int> fileBytes = bytes.toList();
    List<int> header = [];

    for (var element in fileBytes) {
      if (element == 0) return [];
      header.add(element);
    }
    return header;
  }
}
