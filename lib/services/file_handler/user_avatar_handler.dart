import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:path/path.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/file_handler/voce_file_handler.dart';

class UserAvatarHander extends VoceFileHander {
  static const String _pathStr = "user_avatar";
  UserAvatarHander() : super();

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

  static String generateFileName(UserInfoM userInfoM) {
    final avatarUpdatedAt = userInfoM.userInfo.avatarUpdatedAt;
    return "${userInfoM.uid}_$avatarUpdatedAt.png";
  }

  /// Read file from local storage, if not exist, fetch from server.
  Future<File?> readOrFetch(UserInfoM userInfoM, {String? dbName}) async {
    final fileName = generateFileName(userInfoM);
    final file = await read(fileName, dbName: dbName);

    if (file != null) {
      final avatarFileUpdatedAt =
          int.parse(basenameWithoutExtension(file.path).split("_").last);
      if (avatarFileUpdatedAt == userInfoM.userInfo.avatarUpdatedAt) {
        return file;
      }
    }

    try {
      final resourceApi = ResourceApi();
      final res = await resourceApi.getUserAvatar(userInfoM.uid);
      if (res.statusCode == 200 && res.data != null && res.data!.isNotEmpty) {
        final file =
            await save(generateFileName(userInfoM), res.data!, dbName: dbName);
        return file;
      }
    } catch (e) {
      App.logger.warning(e);
    }

    return null;
  }
}
