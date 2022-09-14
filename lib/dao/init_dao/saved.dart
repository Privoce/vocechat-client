// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:simple_logger/simple_logger.dart';

class SavedM with M {
  String _saved = "";
  String properties = "";

  SavedM();

  SavedM.item(String id, this._saved, int createdAt, this.properties) {
    super.id = id;
    super.createdAt = createdAt;
  }

  Archive? get saved {
    try {
      return Archive.fromJson(json.decode(_saved));
    } catch (e) {
      App.logger.severe(e);
      return null;
    }
  }

  static SavedM fromMap(Map<String, dynamic> map) {
    SavedM m = SavedM();
    if (map.containsKey(F_id)) {
      m.id = map[F_id];
    }
    if (map.containsKey(F_saved)) {
      m._saved = map[F_saved];
    }
    if (map.containsKey(F_properties)) {
      m.properties = map[F_properties];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }
    return m;
  }

  static const F_tableName = "saved";
  static const F_id = "id";
  static const F_saved = "saved";
  static const F_properties = "properties";
  static const F_createdAt = "created_at";

  @override
  Map<String, Object> get values => {
        SavedM.F_id: id,
        SavedM.F_saved: _saved,
        SavedM.F_properties: properties,
        SavedM.F_createdAt: createdAt
      };

  static MMeta meta = MMeta.fromType(SavedM, SavedM.fromMap)
    ..tableName = F_tableName;
}

class SavedDao extends Dao<SavedM> {
  final _logger = SimpleLogger();

  SavedDao() {
    SavedM.meta;
  }

  Future<SavedM> addOrUpdate(SavedM m) async {
    SavedM? old = await first(where: '${SavedM.F_id} = ?', whereArgs: [m.id]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = old.createdAt;
      await super.update(m);
    } else {
      await super.add(m);
    }
    _logger.info("Saved item saved. Id: ${m.id}");
    return m;
  }

  Future<List<String>> getSavedIdList() async {
    final savedMList = await list();
    return savedMList.map((e) => e.id).toList();
  }

  Future<SavedM?> getSaved(String id) async {
    return super.first(where: "${SavedM.F_id} = ?", whereArgs: [id]);
  }

  Future<List<SavedM>?> getSavedListByChat({int? gid, int? uid}) async {
    String sqlStr;
    if (gid != null) {
      sqlStr =
          "SELECT * FROM ${SavedM.F_tableName} WHERE json_extract(${SavedM.F_saved}, '\$.messages[0].source.gid') LIKE $gid";
    } else {
      sqlStr =
          "SELECT * FROM ${SavedM.F_tableName} WHERE json_extract(${SavedM.F_saved}, '\$.messages[0].source.uid') LIKE $uid";
    }

    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);

    if (records.isNotEmpty) {
      final result = records.map((e) => SavedM.fromMap(e)).toList();
      return result;
    }
    return null;
  }
}
