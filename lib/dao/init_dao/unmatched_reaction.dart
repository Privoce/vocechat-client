// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:simple_logger/simple_logger.dart';

class UnmatchedReactionM with M {
  int targetMid = -1;
  String reactionList = "";

  UnmatchedReactionM();

  UnmatchedReactionM.item(id, this.targetMid, this.reactionList, createdAt) {
    super.id = id;
    super.createdAt = createdAt;
  }

  UnmatchedReactionM.add(this.targetMid, this.reactionList);

  static UnmatchedReactionM fromMap(Map<String, dynamic> map) {
    UnmatchedReactionM m = UnmatchedReactionM();
    if (map.containsKey(F_id)) {
      m.id = map[F_id];
    }
    if (map.containsKey(F_targetMid)) {
      m.targetMid = map[F_targetMid];
    }
    if (map.containsKey(F_reactionList)) {
      m.reactionList = map[F_reactionList];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }
    return m;
  }

  static const F_tableName = "unmatched_reaction";
  static const F_id = "id";
  static const F_targetMid = "target_mid";
  static const F_reactionList = "reaction_list";
  static const F_createdAt = "created_at";

  @override
  Map<String, Object> get values => {
        UnmatchedReactionM.F_id: id,
        UnmatchedReactionM.F_targetMid: targetMid,
        UnmatchedReactionM.F_reactionList: reactionList,
        UnmatchedReactionM.F_createdAt: createdAt
      };

  static MMeta meta =
      MMeta.fromType(UnmatchedReactionM, UnmatchedReactionM.fromMap)
        ..tableName = F_tableName;
}

class UnmatchedReactionDao extends Dao<UnmatchedReactionM> {
  final _logger = SimpleLogger();

  UnmatchedReactionDao() {
    UnmatchedReactionM.meta;
  }

  Future<UnmatchedReactionM> addOrUpdate(UnmatchedReactionM m) async {
    UnmatchedReactionM? old = await first(
        where: '${UnmatchedReactionM.F_targetMid} = ?',
        whereArgs: [m.targetMid]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = old.createdAt;
      await super.update(m);
    } else {
      await super.add(m);
    }
    _logger.info("imageM saved. Id: ${m.id}");
    return m;
  }

  Future<UnmatchedReactionM> addReaction(
      int targetMid, String reactionMsg) async {
    UnmatchedReactionM? old = await first(
        where: '${UnmatchedReactionM.F_targetMid} = ?', whereArgs: [targetMid]);
    if (old != null) {
      final reactionList = jsonDecode(old.reactionList) as List<dynamic>;
      reactionList.add(reactionMsg);
      await super.update(old);
      return old;
    } else {
      final newRecord =
          UnmatchedReactionM.add(targetMid, jsonEncode([reactionMsg]));
      await super.add(newRecord);
      return newRecord;
    }
  }

  Future<UnmatchedReactionM?> getUnmatchedReactions(int mid) async {
    return super.first(
        where: "${UnmatchedReactionM.F_targetMid} = ?", whereArgs: [mid]);
  }

  Future<int> deleteReactions(int targetMid) async {
    final res = await db.delete(UnmatchedReactionM.F_tableName,
        where: "${UnmatchedReactionM.F_targetMid} = ?", whereArgs: [targetMid]);
    if (res > 0) {
      App.logger.info("Msg deleted. Mid: $targetMid");
    } else {
      App.logger.warning("Msg not found. Mid: $targetMid");
    }

    return res;
  }
}
