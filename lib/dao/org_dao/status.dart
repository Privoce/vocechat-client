// ignore_for_file: constant_identifier_names

import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';

class StatusM with M {
  // @override
  // List<Object?> get props => [url];

  /// ID primary key，同 url
  String userDbId = "";

  StatusM();

  StatusM.item(this.userDbId);

  static StatusM fromMap(Map<String, dynamic> map) {
    StatusM m = StatusM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }

    if (map.containsKey(F_userDbId)) {
      m.userDbId = map[F_userDbId];
    }

    return m;
  }

  static const F_tableName = "status";
  static const F_userDbId = "user_db_id";

  @override
  Map<String, Object> get values => {StatusM.F_userDbId: userDbId};

  static MMeta meta = MMeta.fromType(StatusM, StatusM.fromMap)
    ..tableName = F_tableName;
}

class StatusMDao extends OrgDao<StatusM> {
  static final StatusMDao dao = StatusMDao._p();

  StatusMDao._p() {
    StatusM.meta;
  }

  /// Add or replace the only one(current) user_db.
  Future<StatusM?> getStatus() async {
    final res = await super.list();
    if (res.length > 1 || res.isEmpty) {
      App.logger.config(
          "Current status quantity not equal to 1. Db number: ${res.length}");
      for (var s in res) {
        App.logger.warning(s.userDbId);
      }
      return null;
    }
    return res.first;
  }

  Future<StatusM?> getStatusByUserDbId(String id) async {
    return super.first(where: "${StatusM.F_userDbId} = ?", whereArgs: [id]);
    // final res = await super.list();
    // if (res.length > 1 || res.isEmpty) {
    //   App.logger.severe("Current status quantity not equal to 1");
    //   return null;
    // }
    // return res.first;
  }

  Future<StatusM> addOrUpdate(StatusM m) async {
    final old = await super
        .first(where: "${StatusM.F_userDbId} = ?", whereArgs: [m.userDbId]);
    if (old != null) {
      m.id = old.id;
      await super.update(m);
    } else {
      await super.add(m);
    }
    App.logger.info("Status updated. Current userDbId: ${m.userDbId}");
    return m;
  }

  Future<StatusM> replace(StatusM m) async {
    await super.removeAll();
    await super.add(m);
    return m;
  }
}

class StatusDbException implements Exception {
  String message;
  StatusDbException([this.message = ""]);

  @override
  String toString() => "FormatException: $message";
}
