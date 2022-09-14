import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:vocechat_client/api/lib/resource_api.dart';
import 'package:vocechat_client/api/lib/saved_api.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/app_methods.dart';
import 'package:vocechat_client/dao/init_dao/chat_msg.dart';

enum FileType { file, image, thumb }

class FileHandler {
  /// This singleton class handles file saving to and retrieving from local data
  /// storage.
  FileHandler();

  FileHandler._singleton();
  static final FileHandler singleton = FileHandler._singleton();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> imageThumbPath(
      String chatId, String localMid, String fileName) async {
    return "${await _localPath}/file/${App.app.userDb!.dbName}/$chatId/image_thumb/$localMid/$fileName";
  }

  Future<String> _imageNormalPath(
      String chatId, String localMid, String fileName) async {
    return "${await _localPath}/file/${App.app.userDb!.dbName}/$chatId/image_normal/$localMid/$fileName";
  }

  Future<String> _filePath(
      String chatId, String localMid, String fileName) async {
    return "${await _localPath}/file/${App.app.userDb!.dbName}/$chatId/file/$localMid/$fileName";
  }

  Future<String> _archiveFilePath(
      String archiveId, int attachmentId, String fileName) async {
    return "${await _localPath}/file/${App.app.userDb!.dbName}/archive_file/$archiveId/$attachmentId/$fileName";
  }

  Future<String> _savedItemsFilePath(
      String archiveId, int attachmentId, String fileName) async {
    return "${await _localPath}/file/${App.app.userDb!.dbName}/saved_items_file/$archiveId/$attachmentId/$fileName";
  }

  Future<bool> imageThumbExists(
      String chatId, String localMid, String fileName) async {
    return File(await imageThumbPath(chatId, localMid, fileName)).exists();
  }

  Future<bool> imageNormalExists(
      String chatId, String localMid, String fileName) async {
    return File(await _imageNormalPath(chatId, localMid, fileName)).exists();
  }

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
      return null;
    }
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

    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
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
    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return false;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];
    return _deleteFile(chatId, localMid, fileName, FileType.thumb);
  }

  Future<bool> deleteImageWithChatMsgM(ChatMsgM chatMsgM) async {
    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return false;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];
    return _deleteFile(chatId, localMid, fileName, FileType.image);
  }

  Future<bool> deleteFileWithChatMsgM(ChatMsgM chatMsgM) async {
    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
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
    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    return readImageThumb(chatId, localMid, fileName);
  }

  /// Thumb, image use filePath as filename, instead of original filaName.
  ///
  /// Original file name can be retrieved from corresponding chat message.
  Future<File?> getImageThumb(ChatMsgM chatMsgM) async {
    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
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
    ResourceApi resourceApi = ResourceApi(App.app.chatServerM.fullUrl);

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

  /// Retrieve original image file from local document storage.
  Future<File?> getLocalImageNormal(ChatMsgM chatMsgM) async {
    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
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
    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
    if (chatId == null) {
      App.logger.warning("Chat not found, mid: ${chatMsgM.mid}");
      return null;
    }

    String filePath = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply!.content;
    String localMid = chatMsgM.localMid;
    String fileName = chatMsgM.msgNormal?.properties?["name"];

    ResourceApi resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
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

  /// Retrieve original image file from local document storage.
  Future<File?> getLocalFile(ChatMsgM chatMsgM) async {
    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
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
    final chatId = getChatId(uid: chatMsgM.dmUid, gid: chatMsgM.gid);
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

    ResourceApi resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
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

  Future<File?> getArchiveFile(String archiveId, int attachmentId,
      [String? fileName, Function(int, int)? onProgress]) async {
    String _fileName =
        (fileName != null && fileName.isNotEmpty) ? fileName : "avatar";
    if (await archiveFileExists(archiveId, attachmentId, _fileName)) {
      return readArchiveFile(archiveId, attachmentId, _fileName);
    }

    try {
      final resourceApi = ResourceApi(App.app.chatServerM.fullUrl);
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
        (fileName != null && fileName.isNotEmpty) ? fileName : "avatar";
    if (await savedItemsFileExists(archiveId, attachmentId, _fileName)) {
      return readSavedItemsFile(archiveId, attachmentId, _fileName);
    }
    return null;
  }

  Future<File?> getSavedItemsFile(int uid, String archiveId, int attachmentId,
      [String? fileName, Function(int, int)? onProgress]) async {
    String _fileName =
        (fileName != null && fileName.isNotEmpty) ? fileName : "avatar";
    if (await savedItemsFileExists(archiveId, attachmentId, _fileName)) {
      return readSavedItemsFile(archiveId, attachmentId, _fileName);
    }

    try {
      final savedItemsApi = SavedApi(App.app.chatServerM.fullUrl);
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
