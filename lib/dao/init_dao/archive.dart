// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:vocechat_client/api/models/msg/msg_archive/archive.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:simple_logger/simple_logger.dart';

class ArchiveM with M {
  String _archive = "";

  ArchiveM();

  ArchiveM.item(String id, this._archive, int createdAt) {
    super.id = id;
    super.createdAt = createdAt;
  }

  Archive? get archive {
    try {
      return Archive.fromJson(json.decode(_archive));
    } catch (e) {
      App.logger.severe(e);
      return null;
    }
  }

  static ArchiveM fromMap(Map<String, dynamic> map) {
    ArchiveM m = ArchiveM();
    if (map.containsKey(F_id)) {
      m.id = map[F_id];
    }
    if (map.containsKey(F_archive)) {
      m._archive = map[F_archive];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }
    return m;
  }

  static const F_tableName = "archive";
  static const F_id = "id";
  static const F_archive = "archive";
  static const F_createdAt = "created_at";

  @override
  Map<String, Object> get values => {
        ArchiveM.F_id: id,
        ArchiveM.F_archive: _archive,
        ArchiveM.F_createdAt: createdAt
      };

  static MMeta meta = MMeta.fromType(ArchiveM, ArchiveM.fromMap)
    ..tableName = F_tableName;
}

class ArchiveDao extends Dao<ArchiveM> {
  ArchiveDao() {
    ArchiveM.meta;
  }

  Future<ArchiveM> addOrUpdate(ArchiveM m) async {
    ArchiveM? old =
        await first(where: '${ArchiveM.F_id} = ?', whereArgs: [m.id]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = old.createdAt;
      await super.update(m);
    } else {
      await super.add(m);
    }
    App.logger.info("Archive saved. Id: ${m.id}");
    return m;
  }

  /// Use *archive Id* to fetch archives. (different from other message types.)
  Future<ArchiveM?> getArchive(String id) async {
    return super.first(where: "${ArchiveM.F_id} = ?", whereArgs: [id]);
  }
}
