// ignore_for_file: constant_identifier_names

import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';

class DmInfoM with M {
  int dmUid = -1;
  String lastLocalMid = "";
  // ignore: prefer_final_fields
  String _properties = "";
  int updatedAt = 0;

  // String get name {}

  DmInfoM();

  DmInfoM.item(this.dmUid, this.lastLocalMid, this.updatedAt);

  static DmInfoM fromMap(Map<String, dynamic> map) {
    DmInfoM m = DmInfoM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_dmUid)) {
      m.dmUid = map[F_dmUid];
    }
    if (map.containsKey(F_lastLocalMid)) {
      m.lastLocalMid = map[F_lastLocalMid];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }
    if (map.containsKey(F_updatedAt)) {
      m.updatedAt = map[F_updatedAt];
    }

    return m;
  }

  static const F_tableName = 'dm_info';
  static const F_dmUid = 'dm_uid';
  static const F_lastLocalMid = 'last_local_mid';
  static const F_createdAt = 'created_at';
  static const F_updatedAt = 'updated_at';

  @override
  Map<String, Object> get values => {
        DmInfoM.F_dmUid: dmUid,
        DmInfoM.F_lastLocalMid: lastLocalMid,
        DmInfoM.F_createdAt: createdAt,
        DmInfoM.F_updatedAt: updatedAt
      };

  static MMeta meta = MMeta.fromType(DmInfoM, DmInfoM.fromMap)
    ..tableName = F_tableName;
}

class DmInfoDao extends Dao<DmInfoM> {
  DmInfoDao() {
    DmInfoM.meta;
  }

  Future<DmInfoM> addOrUpdate(DmInfoM m) async {
    DmInfoM? old =
        await first(where: '${DmInfoM.F_dmUid} = ?', whereArgs: [m.dmUid]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = old.createdAt;
      await super.update(m);
      App.logger.info("DmInfo updated. ${m.dmUid}");
    } else {
      await super.add(m);
      App.logger.info("DmInfo added. ${m.dmUid}");
    }

    return m;
  }

  /// Get a list of Users in UserInfo
  ///
  /// Result shown in
  /// uid, ascending order
  Future<List<DmInfoM>?> getDmList() async {
    String orderBy = "${DmInfoM.F_updatedAt} ASC";
    return super.list(orderBy: orderBy);
  }

  Future<DmInfoM?> getDmInfo(int dmUid) async {
    return await first(where: '${DmInfoM.F_dmUid} = ?', whereArgs: [dmUid]);
  }

  Future<int> removeByDmUid(int dmUid) async {
    MMeta meta = mMetas[DmInfoM]!;
    int count = await db.delete(meta.tableName,
        where: '${DmInfoM.F_dmUid} = ?', whereArgs: [dmUid]);
    return count;
  }
}
