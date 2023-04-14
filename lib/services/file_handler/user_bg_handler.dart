import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/services/file_handler/voce_file_handler.dart';

class UserBgHander extends VoceFileHander {
  static const String _pathStr = "user_background";
  UserBgHander() : super();

  @override
  Future<String> filePath(String fileName,
      {String? chatId, String? dbName}) async {
    final directory = await getApplicationDocumentsDirectory();
    try {
      return "${directory.path}/file/${App.app.userDb!.dbName}/$_pathStr/$String fileName";
    } catch (e) {
      App.logger.severe(e);
      return "";
    }
  }
}
