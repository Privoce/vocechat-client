import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:vocechat_client/services/file_handler/voce_file_handler.dart';
import 'package:vocechat_client/shared_funcs.dart';

class AudioFileHandler extends VoceFileHander {
  // path format: chatId/_pathStr/fileName

  static const String _pathStr = "voice_messages";
  AudioFileHandler() : super();

  @override
  Future<String> filePath(String fileName,
      {String? chatId, String? dbName}) async {
    final directory = await getApplicationDocumentsDirectory();
    final databaseName = dbName ?? App.app.userDb?.dbName;
    try {
      if (databaseName != null && databaseName.isNotEmpty) {
        return "${directory.path}/file/${App.app.userDb!.dbName}/$_pathStr/$fileName";
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return "";
  }

  static String generateFileName(String localMid) {
    return "$localMid.m4a";
  }

  Future<File?> readAudioFile(ChatMsgM chatMsgM,
      {bool serverFetch = true, Function(int, int)? onProgress}) async {
    final filePath = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content;
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    final localMid = chatMsgM.localMid;

    return readOrFetch(filePath ?? "", chatId ?? "", localMid, onProgress,
        serverFetch: serverFetch);
  }

  /// Read file from local storage, if not exist, fetch from server.
  Future<File?> readOrFetch(String filePath, String chatId, String localMid,
      Function(int, int)? onProgress,
      {String? dbName, bool serverFetch = true}) async {
    final localAudioFile =
        await read(generateFileName(localMid), chatId: chatId, dbName: dbName);
    if (localAudioFile != null) {
      return localAudioFile;
    } else {
      // get from server
      try {
        final resourceApi = ResourceApi();
        final res =
            await resourceApi.getFile(filePath, false, true, onProgress);
        if (res.statusCode == 200 && res.data != null && res.data!.isNotEmpty) {
          return save(generateFileName(localMid), res.data!,
              chatId: chatId, dbName: dbName);
        }
      } catch (e) {
        App.logger.warning(e);
      }
    }
    return null;
  }

  /// Delete file from local storage.
  ///
  /// The properties needed are [localMid], [dmUid] and [gid].
  /// If the original [chatMsgM] is not available, a temporary [chatMsgM]
  /// with above mentioned three properties also works.
  Future<bool> deleteWithChatMsgM(ChatMsgM chatMsgM) async {
    final localMid = chatMsgM.localMid;
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    final fileName = generateFileName(localMid);
    return delete(fileName, chatId: chatId);
  }
}
