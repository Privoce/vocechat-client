import 'dart:io';
import 'dart:typed_data';
import 'package:vocechat_client/app.dart';

class VoceFileHander {
  VoceFileHander();

  Future<String> filePath(String fileName) async {
    throw UnimplementedError();
  }

  Future<bool> exists(String fileName) async {
    return File(await filePath(fileName)).exists();
  }

  Future<File?> save(String fileName, Uint8List bytes) async {
    final path = await filePath(fileName);

    try {
      return await File(path)
          .create(recursive: true)
          .then((file) => file.writeAsBytes(bytes));
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<File?> read(String fileName) async {
    final path = await filePath(fileName);
    try {
      return File(path);
    } catch (e) {
      App.logger.severe(e);
    }
    return null;
  }

  Future<bool> delete(String fileName) async {
    final path = await filePath(fileName);
    try {
      final file = await read(path);
      if (file == null) return true; // File does not exist
      await file.delete();
      App.logger.info("File has been deleted. path: $path");
      return true;
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }
}
