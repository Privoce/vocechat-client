// ignore_for_file: constant_identifier_names

import 'dart:typed_data';
import 'package:vocechat_client/dao/dao.dart';
import 'package:simple_logger/simple_logger.dart';

class OpenGraphicThumbnailM with M {
  Uint8List thumbnail = Uint8List(0);
  String fileId = '';
  String siteName = '';
  String description = '';
  String title = '';
  String url = '';
  OpenGraphicThumbnailM();

  OpenGraphicThumbnailM.item(String id, this.fileId, this.thumbnail,
      this.siteName, this.title, this.description, this.url, int createdAt) {
    super.id = id;
    super.createdAt = createdAt;
  }

  static OpenGraphicThumbnailM fromMap(Map<String, dynamic> map) {
    OpenGraphicThumbnailM m = OpenGraphicThumbnailM();
    if (map.containsKey(F_id)) {
      m.id = map[F_id];
    }
    if (map.containsKey(F_fileId)) {
      m.fileId = map[F_fileId];
    }
    if (map.containsKey(F_thumbnail)) {
      m.thumbnail = map[F_thumbnail];
    }
    if (map.containsKey(F_siteName)) {
      m.siteName = map[F_siteName];
    }

    if (map.containsKey(F_title)) {
      m.title = map[F_title];
    }
    if (map.containsKey(F_description)) {
      m.description = map[F_description];
    }
    if (map.containsKey(F_url)) {
      m.url = map[F_url];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }
    return m;
  }

  static const F_tableName = "open_graphic_thumb";
  static const F_id = "id";
  static const F_fileId = "file_id";
  static const F_thumbnail = "thumbnail";
  static const F_siteName = "site_name";
  static const F_title = "title";
  static const F_description = "description";
  static const F_url = "url";
  static const F_createdAt = "created_at";

  @override
  Map<String, Object> get values => {
        OpenGraphicThumbnailM.F_id: id,
        OpenGraphicThumbnailM.F_fileId: fileId,
        OpenGraphicThumbnailM.F_thumbnail: thumbnail,
        OpenGraphicThumbnailM.F_siteName: siteName,
        OpenGraphicThumbnailM.F_title: title,
        OpenGraphicThumbnailM.F_description: description,
        OpenGraphicThumbnailM.F_url: url,
        OpenGraphicThumbnailM.F_createdAt: createdAt
      };

  static MMeta meta =
      MMeta.fromType(OpenGraphicThumbnailM, OpenGraphicThumbnailM.fromMap)
        ..tableName = F_tableName;
}

class OpenGraphicThumbnailDao extends Dao<OpenGraphicThumbnailM> {
  final _logger = SimpleLogger();

  OpenGraphicThumbnailDao() {
    OpenGraphicThumbnailM.meta;
  }

  Future<OpenGraphicThumbnailM> addOrUpdate(OpenGraphicThumbnailM m) async {
    OpenGraphicThumbnailM? old = await first(
        where: '${OpenGraphicThumbnailM.F_id} = ?', whereArgs: [m.id]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = old.createdAt;
      await super.update(m);
    } else {
      await super.add(m);
    }
    _logger
        .info("OpenGraphicThumbnailM saved. Id: ${m.id} ${m.title} ${m.url}");
    return m;
  }

  Future<List<OpenGraphicThumbnailM>> getThumb(String id) async {
    return super.query(
        columns: ['id', 'thumbnail', 'siteName', 'title', 'description', 'url'],
        where: "${OpenGraphicThumbnailM.F_id} = ?",
        whereArgs: [id]);
  }

  Future<OpenGraphicThumbnailM?> getThumbByFileId(String fileId) async {
    return super.first(
        where: "${OpenGraphicThumbnailM.F_fileId} = ?", whereArgs: [fileId]);
  }
}
