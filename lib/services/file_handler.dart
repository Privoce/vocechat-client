import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/api/lib/saved_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';
import 'package:path/path.dart' as p;
import 'package:vocechat_client/shared_funcs.dart';

enum FileType { file, image, thumb, videoThumb }

class FileHandler {
  /// This singleton class handles file saving to and retrieving from local data
  /// storage.
  FileHandler(String path);

  FileHandler._singleton();
  static final FileHandler singleton = FileHandler._singleton();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get image thumb with [chatId] and [localMid].
  ///
  /// [fileName] is used to get file extension.
  Future<String> imageThumbPath(
      String chatId, String localMid, String fileName) async {
    // Use localMid as filename to avoid special chars.
    final extension = p.extension(fileName);
    return "${await _localPath}/file/${App.app.userDb!.dbName}/$chatId/image_thumb/$localMid$extension";
  }

  Future<String> _imageNormalPath(
      String chatId, String localMid, String fileName) async {
    final extension = p.extension(fileName);
    return "${await _localPath}/file/${App.app.userDb!.dbName}/$chatId/image_normal/$localMid$extension";
  }

  Future<String> _userAvatarPath(int uid) async {
    return "${await _localPath}/file/${App.app.userDb!.dbName}/user_avatar/$uid.jpg";
  }

  Future<String> _channelAvatarPath(int gid) async {
    return "${await _localPath}/file/${App.app.userDb!.dbName}/channel_avatar/$gid.jpg";
  }

  Future<String> _userChatBgPath(int uid) async {
    return "${await _localPath}/file/${App.app.userDb!.dbName}/user_background/$uid.jpg";
  }

  Future<String> _channelChatBgPath(int gid) async {
    return "${await _localPath}/file/${App.app.userDb!.dbName}/channel_background/$gid.jpg";
  }

  Future<String> videoThumbPath(
      String chatId, String localMid, String fileName) async {
    final extension = p.extension(fileName);
    return "${await _localPath}/file/${App.app.userDb!.dbName}/$chatId/video_thumb/$localMid$extension";
  }

  Future<String> _filePath(
      String chatId, String localMid, String fileName) async {
    final extension = p.extension(fileName);
    return "${await _localPath}/file/${App.app.userDb!.dbName}/$chatId/file/$localMid$extension";
  }

  Future<String> _archiveFilePath(
      String archiveId, int attachmentId, String fileName) async {
    final extension = p.extension(fileName);
    return "${await _localPath}/file/${App.app.userDb!.dbName}/archive_file/$archiveId/$attachmentId$extension";
  }

  Future<String> _savedItemsFilePath(
      String archiveId, int attachmentId, String fileName) async {
    final extension = p.extension(fileName);
    return "${await _localPath}/file/${App.app.userDb!.dbName}/saved_items_file/$archiveId/$attachmentId$extension";
  }

  Future<bool> imageThumbExists(
      String chatId, String localMid, String fileName) async {
    return File(await imageThumbPath(chatId, localMid, fileName)).exists();
  }

  Future<bool> imageNormalExists(
      String chatId, String localMid, String fileName) async {
    return File(await _imageNormalPath(chatId, localMid, fileName)).exists();
  }

  Future<bool> userAvatarExists(int uid) async {
    return File(await _userAvatarPath(uid)).exists();
  }

  Future<bool> channelAvatarExists(int gid) async {
    return File(await _channelAvatarPath(gid)).exists();
  }

  Future<bool> userBgExists(int uid, String fileName) async {
    return File(await _userChatBgPath(uid)).exists();
  }

  Future<bool> channelBgExists(int gid, String fileName) async {
    return File(await _channelChatBgPath(gid)).exists();
  }

  // Future<bool> videoThumbExists(
  //     String chatId, String localMid, String fileName) async {
  //   return File(await videoThumbPath(chatId, localMid, fileName)).exists();
  // }

  Future<bool> fileExists(
      String chatId, String localMid, String fileName) async {
    return File(await _filePath(chatId, localMid, fileName)).exists();
  }

  Future<bool> archiveFileExists(
      String archiveId, int attachmentId, String fileName) async {
    return File(await _archiveFilePath(archiveId, attachmentId, fileName))
        .exists();
  }

  Future<bool> savedItemsFileExists(
      String archiveId, int attachmentId, String fileName) async {
    return File(await _savedItemsFilePath(archiveId, attachmentId, fileName))
        .exists();
  }

  Future<File?> saveImageThumb(
      String chatId, Uint8List bytes, String localMid, String fileName) async {
    return _save(chatId, bytes, localMid, fileName, FileType.thumb);
  }

  Future<File?> saveImageNormal(
      String chatId, Uint8List bytes, String localMid, String fileName) async {
    return _save(chatId, bytes, localMid, fileName, FileType.image);
  }

  Future<File?> saveUserAvatar(int uid, Uint8List bytes) async {
    final path = await _userAvatarPath(uid);

    try {
      return await File(path)
          .create(recursive: true)
          .then((file) => file.writeAsBytes(bytes));
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> saveChannelAvatar(int gid, Uint8List bytes) async {
    final path = await _channelAvatarPath(gid);

    try {
      return await File(path)
          .create(recursive: true)
          .then((file) => file.writeAsBytes(bytes));
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> saveUserBg(int uid, Uint8List bytes) async {
    final path = await _userChatBgPath(uid);

    try {
      return await File(path)
          .create(recursive: true)
          .then((file) => file.writeAsBytes(bytes));
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> saveChannelBg(int gid, Uint8List bytes) async {
    final path = await _channelChatBgPath(gid);

    try {
      return await File(path)
          .create(recursive: true)
          .then((file) => file.writeAsBytes(bytes));
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> saveFile(
      String chatId, Uint8List bytes, String localMid, String fileName) async {
    return _save(chatId, bytes, localMid, fileName, FileType.file);
  }

  Future<File?> saveArchiveFile(Uint8List bytes, String archiveId,
      int attachmentId, String fileName) async {
    final path = await _archiveFilePath(archiveId, attachmentId, fileName);

    try {
      return await File(path)
          .create(recursive: true)
          .then((file) => file.writeAsBytes(bytes));
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> saveSavedItemsFile(Uint8List bytes, String archiveId,
      int attachmentId, String fileName) async {
    final path = await _savedItemsFilePath(archiveId, attachmentId, fileName);

    try {
      return await File(path)
          .create(recursive: true)
          .then((file) => file.writeAsBytes(bytes));
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> _save(String chatId, Uint8List bytes, String localMid,
      String fileName, FileType type) async {
    try {
      String path;

      switch (type) {
        case FileType.file:
          path = await _filePath(chatId, localMid, fileName);
          break;
        case FileType.image:
          path = await _imageNormalPath(chatId, localMid, fileName);
          break;
        case FileType.thumb:
          path = await imageThumbPath(chatId, localMid, fileName);
          break;
        default:
          path = await _filePath(chatId, localMid, fileName);
          break;
      }

      return await File(path)
          .create(recursive: true)
          .then((file) => file.writeAsBytes(bytes));
    } catch (e) {
      App.logger.severe(e);
    }

    return null;
  }

  Future<File?> readImageThumb(
      String chatId, String localMid, String fileName) async {
    return _read(chatId, localMid, fileName, FileType.thumb);
  }

  Future<File?> readImageNormal(
      String chatId, String localMid, String fileName) async {
    return _read(chatId, localMid, fileName, FileType.image);
  }

  Future<File?> readFile(String chatId, localMid, String fileName) async {
    return _read(chatId, localMid, fileName, FileType.file);
  }

  Future<File?> readVideoThumb(String chatId, localMid, String fileName) async {
    return _read(chatId, localMid, fileName, FileType.videoThumb);
  }

  Future<File?> readArchiveFile(
      String archiveId, int attachmentId, String fileName) async {
    try {
      String path = await _archiveFilePath(archiveId, attachmentId, fileName);
      if (!await File(path).exists()) {
        throw "File not exist: $fileName, path: $path";
      }
      return File(path);
    } catch (e) {
      App.logger.severe(e);
      return null;
    }
  }

  Future<File?> readSavedItemsFile(
      String archiveId, int attachmentId, String fileName) async {
    try {
      String path =
          await _savedItemsFilePath(archiveId, attachmentId, fileName);
      if (!await File(path).exists()) {
        throw "File not exist: $fileName, path: $path";
      }
      return File(path);
    } catch (e) {
      App.logger.severe(e);
      return null;
    }
  }

  Future<File?> _read(
      String chatId, String localMid, String fileName, FileType type) async {
    try {
      String path;
      switch (type) {
        case FileType.file:
          path = await _filePath(chatId, localMid, fileName);
          break;
        case FileType.image:
          path = await _imageNormalPath(chatId, localMid, fileName);
          break;
        case FileType.thumb:
          path = await imageThumbPath(chatId, localMid, fileName);
          break;
        case FileType.videoThumb:
          path = await videoThumbPath(chatId, localMid, fileName);
          break;
        default:
          path = await _filePath(chatId, localMid, fileName);
          break;
      }
      if (!await File(path).exists()) {
        throw "File not exist: $fileName, path: $path";
      }

      return File(path);
    } catch (e) {
      App.logger.warning(e);
    }
    return null;
  }

  Future<bool> deleteImageThumb(
      String chatId, String localMid, String fileName) async {
    return _deleteFile(chatId, localMid, fileName, FileType.thumb);
  }

  Future<bool> deleteImageNormal(
      String chatId, String localMid, String fileName) async {
    return _deleteFile(chatId, localMid, fileName, FileType.image);
  }

  Future<bool> deleteFile(
      String chatId, String localMid, String fileName) async {
    return _deleteFile(chatId, localMid, fileName, FileType.file);
  }

  /// It will delete all possible files, including thumbs, images and files
  /// attached to [chatMsgM].
  ///
  /// Thumbs, images and files are named after their filePath.
  /// File names will not duplicate normally.
  Future<bool> deleteWithChatMsgM(ChatMsgM chatMsgM) async {
    if (!chatMsgM.isFileMsg) {
      return true;
    }

    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return false;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];
    final ext = fileName.split(".").last.toLowerCase();
    if (ext.isEmpty) {
      return false;
    }

    return await _deleteFile(chatId, localMid, fileName, FileType.thumb) &&
        await _deleteFile(chatId, localMid, fileName, FileType.image) &&
        await _deleteFile(chatId, localMid, fileName, FileType.file);
  }

  Future<bool> deleteThumbWithChatMsgM(ChatMsgM chatMsgM) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return false;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];
    return _deleteFile(chatId, localMid, fileName, FileType.thumb);
  }

  Future<bool> deleteImageWithChatMsgM(ChatMsgM chatMsgM) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return false;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];
    return _deleteFile(chatId, localMid, fileName, FileType.image);
  }

  Future<bool> deleteFileWithChatMsgM(ChatMsgM chatMsgM) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return false;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];
    return _deleteFile(chatId, localMid, fileName, FileType.file);
  }

  Future<bool> _deleteFile(
      String chatId, String localMid, String fileName, FileType type) async {
    try {
      final file = await _read(chatId, localMid, fileName, type);
      if (file == null) return true;
      await file.delete();
      App.logger.info("Image/File has been deleted. chatId: $chatId");
    } catch (e) {
      App.logger.severe(e);
      return false;
    }
    return true;
  }

  // Future<bool> deleteArchiveWithChatMsgM(ChatMsgM chatMsgM) async {
  //   return true;
  // }

  Future<bool> deleteSavedItem(String archiveId) async {
    try {
      final dir = Directory("${await _localPath}/saved_items_file/$archiveId");
      dir.deleteSync(recursive: true);
      return true;
    } catch (e) {
      // App.logger.warning(e);
    }
    return false;
  }

  Future<bool> deleteChatDirectory(String chatId) async {
    try {
      final dir = Directory("${await _localPath}/$chatId");
      dir.deleteSync(recursive: true);
    } catch (e) {
      App.logger.warning(e);
      return false;
    }
    return true;
  }

  /// Retrieve thumb file from local document storage.
  Future<File?> getLocalImageThumb(ChatMsgM chatMsgM) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    return readImageThumb(chatId, localMid, fileName);
  }

  // /// Retrieve the previous thumb file before the current one from
  // /// local document storage.
  // Future<SingleImageItem?> getPreLocalImageThumb(ChatMsgM chatMsgM) async {
  //   final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
  //   if (chatId == null) {
  //     App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
  //     return null;
  //   }

  //   final preChatMsgM = await ChatMsgDao().getImageMsgBeforeMid(chatMsgM.mid);
  //   if (preChatMsgM != null) {
  //     String localMid = preChatMsgM.localMid;
  //     String? fileName = preChatMsgM.msgNormal?.properties?["name"];
  //     print(preChatMsgM.values);
  //     if (fileName != null) {
  //       final file = await readImageThumb(chatId, localMid, fileName);
  //       if (file != null) {
  //         return SingleImageItem(initImageFile: file, chatMsgM: preChatMsgM);
  //       }
  //     }
  //   }
  //   return null;
  // }

  // /// Retrieve the next thumb file before the current one from
  // /// local document storage.
  // Future<SingleImageItem?> getNextLocalImageThumb(ChatMsgM chatMsgM) async {
  //   final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
  //   if (chatId == null) {
  //     App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
  //     return null;
  //   }

  //   final nextChatMsgM = await ChatMsgDao().getImageMsgAfterMid(chatMsgM.mid);
  //   if (nextChatMsgM != null) {
  //     String localMid = nextChatMsgM.localMid;
  //     String fileName = nextChatMsgM.msgNormal?.properties?["name"];
  //     final file = await readImageThumb(chatId, localMid, fileName);
  //     if (file != null) {
  //       return SingleImageItem(initImageFile: file, chatMsgM: nextChatMsgM);
  //     }
  //   }
  //   return null;
  // }

  /// Thumb, image use filePath as filename, instead of original filaName.
  ///
  /// Original file name can be retrieved from corresponding chat message.
  Future<File?> getImageThumb(ChatMsgM chatMsgM) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String filePath = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply!.content;
    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    // try local storage first.
    if (await imageThumbExists(chatId, localMid, fileName)) {
      final file = await readImageThumb(chatId, localMid, fileName);
      return file;
    }

    // try server.
    ResourceApi resourceApi = ResourceApi();

    try {
      final res = await resourceApi.getFile(filePath, true, true);
      if (res.statusCode == 200 && res.data != null) {
        return saveImageThumb(chatId, res.data!, localMid, fileName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> getServerImageThumb(ChatMsgM chatMsgM,
      {void Function(int progress, int total)? onReceiveProgress}) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String filePath = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply!.content;
    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    // try server.
    ResourceApi resourceApi = ResourceApi();

    try {
      final res =
          await resourceApi.getFile(filePath, true, true, onReceiveProgress);
      if (res.statusCode == 200 && res.data != null) {
        return saveImageThumb(chatId, res.data!, localMid, fileName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  /// Retrieve original image file from local document storage.
  Future<File?> getLocalImageNormal(ChatMsgM chatMsgM) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    return readImageNormal(chatId, localMid, fileName);
  }

  /// Thumb, image use filePath as filename, instead of original filaName.
  ///
  /// Original file name can be retrieved from corresponding chat message.
  Future<File?> getImageNormal(ChatMsgM chatMsgM) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String filePath = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply!.content;
    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    ResourceApi resourceApi = ResourceApi();
    if (await imageNormalExists(chatId, localMid, fileName)) {
      final file = await readImageNormal(chatId, localMid, fileName);
      return file;
    }

    try {
      final res = await resourceApi.getFile(filePath, false, true);
      if (res.statusCode == 200 && res.data != null) {
        return saveImageNormal(chatId, res.data!, localMid, fileName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> getServerImageNormal(ChatMsgM chatMsgM,
      {void Function(int progress, int total)? onReceiveProgress}) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String filePath = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply!.content;
    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    // try server.
    ResourceApi resourceApi = ResourceApi();
    try {
      final res =
          await resourceApi.getFile(filePath, false, true, onReceiveProgress);
      if (res.statusCode == 200 && res.data != null) {
        return saveImageNormal(chatId, res.data!, localMid, fileName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  /// Get image file saved locally.
  ///
  /// Will return imageNormal if exists, otherwise return imageThumb.
  /// If these two files are not available, return null.
  Future<File?> getLocalImage(ChatMsgM chatMsgM) async {
    return (await getLocalImageNormal(chatMsgM)) ??
        (await getLocalImageThumb(chatMsgM));
  }

  // Future<File?> getVideoThumb(ChatMsgM chatMsgM) async {
  //   final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
  //   if (chatId == null) {
  //     App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
  //     return null;
  //   }

  //   String filePath = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply!.content;
  //   String localMid = chatMsgM.localMid;
  //   String fileName = chatMsgM.msgNormal?.properties?["name"];

  //   if (await videoThumbExists(chatId, localMid, fileName)) {
  //     final file = await readVideoThumb(chatId, localMid, fileName);
  //     return file;
  //   }

  //   if (await fileExists(chatId, localMid, fileName)) {
  //     final file = await readFile(chatId, localMid, fileName);
  //     if (file != null) {
  //       final videoThumbName = await VideoThumbnail.thumbnailFile(
  //           video: file.path,
  //           thumbnailPath: await videoThumbPath(chatId, localMid, ""),
  //           maxHeight: 200,
  //           quality: 75);
  //       if (videoThumbName != null) {
  //         return readVideoThumb(chatId, localMid, videoThumbName);
  //       }
  //     }
  //   }

  //   final videoUrl =
  //       "${App.app.chatServerM.fullUrl}/api/resource/file?file_path=$filePath&thumbnail=false";
  //   // final videoUrl = "https://www.youtube.com/watch?v=48G5uuAoWXQ";
  //   // print(videoUrl);

  //   final videoThumbName = await VideoThumbnail.thumbnailFile(
  //       video: videoUrl,
  //       thumbnailPath: await videoThumbPath(chatId, localMid, ""),
  //       maxHeight: 200,
  //       quality: 75);

  //   if (videoThumbName != null) {
  //     return readVideoThumb(chatId, localMid, videoThumbName);
  //   } else {
  //     return null;
  //   }
  // }

  /// Retrieve original image file from local document storage.
  Future<File?> getLocalFile(ChatMsgM chatMsgM) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    return readFile(chatId, localMid, fileName);
  }

  /// Thumb, image use filePath as filename, instead of original filaName.
  ///
  /// Original file name can be retrieved from corresponding chat message.
  Future<File?> getFile(
      ChatMsgM chatMsgM, Function(int, int) onProgress) async {
    final chatId =
        SharedFuncs.getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String filePath = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply!.content;
    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    if (await fileExists(chatId, localMid, fileName)) {
      final file = await readFile(chatId, localMid, fileName);
      return file;
    }

    ResourceApi resourceApi = ResourceApi();
    try {
      final res = await resourceApi.getFile(filePath, false, true, onProgress);
      if (res.statusCode == 200 && res.data != null) {
        return saveFile(chatId, res.data!, localMid, fileName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> getLocalArchiveFile(String archiveId, int attachmentId,
      [String? fileName]) async {
    String _fileName =
        (fileName != null && fileName.isNotEmpty) ? fileName : "avatar.jpg";
    if (await archiveFileExists(archiveId, attachmentId, _fileName)) {
      return readArchiveFile(archiveId, attachmentId, _fileName);
    }
    return null;
  }

  // Future<File?>

  Future<File?> getArchiveFile(String archiveId, int attachmentId,
      [String? fileName, Function(int, int)? onProgress]) async {
    String _fileName =
        (fileName != null && fileName.isNotEmpty) ? fileName : "avatar.jpg";
    if (await archiveFileExists(archiveId, attachmentId, _fileName)) {
      return readArchiveFile(archiveId, attachmentId, _fileName);
    }

    try {
      final resourceApi = ResourceApi();
      final res = await resourceApi.getArchiveAttachment(
          archiveId, attachmentId, true, onProgress);
      if (res.statusCode == 200 && res.data != null && res.data!.isNotEmpty) {
        return await saveArchiveFile(
            res.data!, archiveId, attachmentId, _fileName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> getLocalSavedItemsFile(
      int uid, String archiveId, int attachmentId,
      [String? fileName]) async {
    String _fileName =
        (fileName != null && fileName.isNotEmpty) ? fileName : "avatar.jpg";
    if (await savedItemsFileExists(archiveId, attachmentId, _fileName)) {
      return readSavedItemsFile(archiveId, attachmentId, _fileName);
    }
    return null;
  }

  Future<File?> getSavedItemsFile(int uid, String archiveId, int attachmentId,
      [String? fileName, Function(int, int)? onProgress]) async {
    String _fileName =
        (fileName != null && fileName.isNotEmpty) ? fileName : "avatar.jpg";
    if (await savedItemsFileExists(archiveId, attachmentId, _fileName)) {
      return readSavedItemsFile(archiveId, attachmentId, _fileName);
    }

    try {
      final savedItemsApi = SavedApi();
      final res = await savedItemsApi.getSavedAttachment(
          uid, archiveId, attachmentId, true, onProgress);
      if (res.statusCode == 200 && res.data != null && res.data!.isNotEmpty) {
        return await saveSavedItemsFile(
            res.data!, archiveId, attachmentId, _fileName);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }
}
