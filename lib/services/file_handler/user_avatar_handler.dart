import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/api/lib/user_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';
import 'package:vocechat_client/services/file_handler/voce_file_handler.dart';

class UserAvatarHander extends VoceFileHander {
  static const String _pathStr = "user_avatar";
  UserAvatarHander() : super();

  @override
  Future<String> filePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    try {
      return "${directory.path}/file/${App.app.userDb!.dbName}/$_pathStr/$fileName";
    } catch (e) {
      App.logger.severe(e);
      return "";
    }
  }

  static String generateFileName(int uid) {
    return "$uid.png";
  }

  /// Read file from local storage, if not exist, fetch from server.
  Future<File?> readOrFetch(int uid) async {
    final fileName = generateFileName(uid);
    final file = await read(fileName);
    if (file != null) {
      return file;
    } else {
      try {
        final resourceApi = ResourceApi();
        final res = await resourceApi.getUserAvatar(uid);
        if (res.statusCode == 200 && res.data != null && res.data!.isNotEmpty) {
          final file = await UserAvatarHander()
              .save(UserAvatarHander.generateFileName(uid), res.data!);
          return file;
        }
      } catch (e) {
        App.logger.warning(e);
      }
    }
    return null;
  }
}
