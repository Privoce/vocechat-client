import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/services/file_handler/voce_file_handler.dart';

class ChannelAvatarHander extends VoceFileHander {
  static const String _pathStr = "channel_avatar";
  ChannelAvatarHander() : super();

  /// Should insert a png file.
  @override
  Future<String> filePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    try {
      return "${directory.path}/file/${App.app.userDb!.dbName}/$_pathStr/$fileName";
    } catch (e) {
      App.logger.severe(e);
      return "${directory.path}/file";
    }
  }
}
