import 'dart:io';
import 'dart:typed_data';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/services/db.dart';

class VoceFileHander {
  VoceFileHander();

  Future<String> filePath(String fileName,
      {String? chatId, String? dbName}) async {
    throw UnimplementedError();
  }

  Future<bool> exists(String fileName, {String? chatId, String? dbName}) async {
    final path = await filePath(fileName, chatId: chatId, dbName: dbName);
    return File(path).exists();
  }

  Future<File?> save(String fileName, Uint8List bytes,
      {String? chatId, String? dbName}) async {
    final path = await filePath(fileName, chatId: chatId, dbName: dbName);

    try {
      final file = await File(path).create(recursive: true);
      await file.writeAsBytes(bytes, mode: FileMode.write);

      return file;
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  /// Read file from local storage.
  ///
  /// Return null if file does not exist.
  Future<File?> read(String fileName, {String? chatId, String? dbName}) async {
    final path = await filePath(fileName, chatId: chatId, dbName: dbName);

    try {
      if (await exists(fileName, chatId: chatId, dbName: dbName)) {
        return File(path);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<bool> delete(String fileName, {String? chatId, String? dbName}) async {
    final path = await filePath(fileName, chatId: chatId, dbName: dbName);
    try {
      final file = await read(fileName, chatId: chatId, dbName: dbName);
      if (file != null) {
        await file.delete();
      }
      App.logger.info("File has been deleted. path: $path");
      return true;
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }
}
