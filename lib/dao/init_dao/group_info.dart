// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:vocechat_client/api/models/group/group_info.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/pinned_msg.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/group_properties.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';

// ignore: must_be_immutable
class GroupInfoM extends Equatable with M {
  int gid = -1;
  String lastLocalMid = "";
  String info = "";
  String _properties = "";
  int _isPublic = 1;
  int _isActive = 1;
  int updatedAt = 0;

  bool get isPublic => _isPublic == 1;
  bool get isActive => _isActive == 1;

  GroupInfoM();

  GroupInfo get groupInfo {
    return GroupInfo.fromJson(jsonDecode(info));
  }

  GroupProperties get properties {
    if (_properties.isNotEmpty) {
      return GroupProperties.fromJson(json.decode(_properties));
    } else {
      return GroupProperties.update();
    }
  }

  GroupInfoM.item(this.gid, this.lastLocalMid, this.info, this._properties,
      this._isPublic, this._isActive, this.updatedAt);

  GroupInfoM.fromGroupInfo(
    GroupInfo groupInfo,
    bool isActive,
  ) {
    gid = groupInfo.gid;
    info = jsonEncode(groupInfo.toJson());
    _isPublic = groupInfo.isPublic ? 1 : 0;
    _isActive = isActive ? 1 : 0;
  }

  static GroupInfoM fromMap(Map<String, dynamic> map) {
    GroupInfoM m = GroupInfoM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_gid)) {
      m.gid = map[F_gid];
    }
    if (map.containsKey(F_lastLocalMid)) {
      m.lastLocalMid = map[F_lastLocalMid];
    }
    if (map.containsKey(F_info)) {
      m.info = map[F_info];
    }
    if (map.containsKey(F_properties)) {
      m._properties = map[F_properties];
    }
    if (map.containsKey(F_isPublic)) {
      m._isPublic = map[F_isPublic];
    }
    if (map.containsKey(F_isActive)) {
      m._isActive = map[F_isActive];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }
    if (map.containsKey(F_updatedAt)) {
      m.updatedAt = map[F_updatedAt];
    }

    return m;
  }

  static const F_tableName = 'group_info';
  static const F_gid = 'gid';
  static const F_lastLocalMid = 'last_local_mid';
  static const F_info = 'info';
  static const F_properties = 'properties';
  static const F_isPublic = 'is_public';
  static const F_isActive = 'is_active';
  static const F_createdAt = 'created_at';
  static const F_updatedAt = 'updated_at';

  @override
  Map<String, Object> get values => {
        GroupInfoM.F_gid: gid,
        GroupInfoM.F_lastLocalMid: lastLocalMid,
        GroupInfoM.F_info: info,
        GroupInfoM.F_properties: _properties,
        GroupInfoM.F_isPublic: _isPublic,
        GroupInfoM.F_isActive: _isActive,
        GroupInfoM.F_createdAt: createdAt,
        GroupInfoM.F_updatedAt: updatedAt,
      };

  static MMeta meta = MMeta.fromType(GroupInfoM, GroupInfoM.fromMap)
    ..tableName = F_tableName;

  @override
  List<Object?> get props =>
      [gid, lastLocalMid, info, _properties, _isPublic, _isActive, createdAt];
}

class GroupInfoDao extends Dao<GroupInfoM> {
  GroupInfoDao() {
    GroupInfoM.meta;
  }

  Future<GroupInfoM> addOrUpdate(GroupInfoM m) async {
    try {
      GroupInfoM? old =
          await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [m.gid]);
      if (old != null) {
        m.id = old.id;
        m.createdAt = old.createdAt;
        m._properties = jsonEncode(old.properties);
        await super.update(m);
      } else {
        await super.add(m);
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return m;
  }

  Future<GroupInfoM> addOrNotUpdate(GroupInfoM m) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [m.gid]);
    if (old != null) {
      return old;
    } else {
      try {
        return await super.add(m);
      } catch (e) {
        App.logger.warning(e);
        await Future.delayed(Duration(milliseconds: 500)).then((value) async {
          return (await first(
                  where: '${GroupInfoM.F_gid} = ?', whereArgs: [m.gid])) ??
              m;
        });
      }
    }
    return m;
  }

  Future<GroupInfoM?> addMembers(int gid, List<int> uids) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    if (old != null) {
      final oldGroupInfo = old.groupInfo;
      final newMemberSet = Set<int>.from(oldGroupInfo.members!)..addAll(uids);
      oldGroupInfo.members = newMemberSet.toList();

      old.info = jsonEncode(oldGroupInfo);
      await super.update(old);
      return old;
    }
    return null;
  }

  Future<GroupInfoM?> removeMembers(int gid, List<int> uids) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    if (old != null) {
      final oldGroupInfo = old.groupInfo;
      final newMemberSet = Set<int>.from(oldGroupInfo.members!)
        ..removeAll(uids);

      oldGroupInfo.members = newMemberSet.toList();

      old.info = jsonEncode(oldGroupInfo);
      await super.update(old);
      return old;
    }
    return null;
  }

  Future<GroupInfoM?> updateLastLocalMidBy(int gid, String lastLocalMid) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    if (old != null) {
      old.lastLocalMid = lastLocalMid;
      await super.update(old);
    }
    return old;
  }

  // Future<GroupInfoM?> updateAvatar(int gid, Uint8List avatarBytes) async {
  //   GroupInfoM? old =
  //       await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
  //   if (old != null) {
  //     old.avatar = avatarBytes;
  //     await super.update(old);
  //   }
  //   return old;
  // }

  Future<GroupInfoM?> updateGroup(int gid,
      {String? description,
      String? name,
      int? owner,
      int? avatarUpdatedAt,
      bool? isPublic}) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    if (old != null) {
      GroupInfo oldInfo = old.groupInfo;
      if (description != null) {
        oldInfo.description = description;
      }
      if (name != null) {
        oldInfo.name = name;
      }
      // if (owner != null) {
      //   oldInfo.owner = owner;
      // }
      if (avatarUpdatedAt != null) {
        oldInfo.avatarUpdatedAt = avatarUpdatedAt;
      }
      if (isPublic != null) {
        old._isPublic = isPublic ? 1 : 0;
        oldInfo.isPublic = isPublic;

        if (isPublic) {
          oldInfo.owner = null;
        } else {
          oldInfo.owner = owner;
        }
      }

      old.info = jsonEncode(oldInfo);
      await super.update(old);
    }
    return old;
  }

  Future<GroupInfoM?> updatePins(int gid, int mid,
      {PinnedMsg? pinnedMsg}) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    if (old != null) {
      GroupInfo oldInfo = old.groupInfo;
      List<PinnedMsg> pins = oldInfo.pinnedMessages;

      // add
      if (pinnedMsg != null) {
        pins.add(pinnedMsg);
      }
      // remove
      else {
        final idx = pins.indexWhere((element) => element.mid == mid);
        if (idx != -1) {
          pins.removeAt(idx);
        }
      }

      oldInfo.pinnedMessages = pins;
      old.info = jsonEncode(oldInfo);
      await super.update(old);
      return old;
    } else {
      return old;
    }
  }

  /// Update properties of GroupInfoM.
  ///
  /// To cancel [pinnedAt], set it to 0 or -1.
  Future<GroupInfoM?> updateProperties(int gid, {String? draft}) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    if (old != null) {
      GroupProperties oldProperties = old.properties;

      if (draft != null) {
        oldProperties.draft = draft;
      }

      old._properties = json.encode(oldProperties);
      await super.update(old);
    }
    return old;
  }

  Future<GroupInfoM?> deactivateGroupByGid(int gid) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    if (old != null) {
      old._isActive = 0;
      await super.update(old);
    }
    return old;
  }

  /// Get all channels, including private and public ones.
  Future<List<GroupInfoM>?> getAllGroupList() async {
    String orderBy = "${GroupInfoM.F_gid} ASC";
    return super.list(orderBy: orderBy);
  }

  /// Get all public channels.
  Future<List<GroupInfoM>?> getChannelList() async {
    String orderBy = "${GroupInfoM.F_gid} ASC";
    return super.query(
        where: "${GroupInfoM.F_isPublic} = ?",
        whereArgs: [1],
        orderBy: orderBy);
  }

  Future<GroupInfoM?> getGroupByGid(int gid) async {
    return super.first(where: "${GroupInfoM.F_gid} = ?", whereArgs: [gid]);
  }

  Future<GroupInfoM?> removeByGid(int gid) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    if (old != null) {
      MMeta meta = mMetas[GroupInfoM]!;
      await db.delete(meta.tableName,
          where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    }
    return old;
  }

  Future<List<UserInfoM>?> getChannelMatched(int gid, String input) async {
    final group = await getGroupByGid(gid);
    if (group == null) {
      return null;
    }

    if (group.isPublic) {
      String sqlStr =
          "SELECT * FROM ${UserInfoM.F_tableName} WHERE json_extract(${UserInfoM.F_info}, '\$.name') LIKE '%$input%'";

      List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
      if (records.isNotEmpty) {
        final result = records.map((e) => UserInfoM.fromMap(e)).toList();
        return result;
      }
    } else {
      final members = group.groupInfo.members;
      if (members != null && members.isNotEmpty) {
        List<UserInfoM> result = [];
        for (var id in members) {
          final userInfoM = await UserInfoDao().getUserByUid(id);
          if (userInfoM != null &&
              userInfoM.userInfo.name
                  .contains(RegExp(input, caseSensitive: false))) {
            result.add(userInfoM);
          }
        }
        return result;
      }
    }
    return null;
  }

  /// Returns all members if [batchSize] is 0.
  Future<List<UserInfoM>?> getUserListByGid(
      int gid, bool isPublic, List<int> memberList,
      {int batchSize = 20}) async {
    List<UserInfoM> users = [];
    if (isPublic) {
      String sqlStr;
      if (batchSize == 0) {
        sqlStr = "SELECT * FROM ${UserInfoM.F_tableName}";
      } else {
        sqlStr = "SELECT * FROM ${UserInfoM.F_tableName} LIMIT $batchSize";
      }
      List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
      if (records.isNotEmpty) {
        users = records.map((e) => UserInfoM.fromMap(e)).toList();
      }
    } else {
      if (batchSize != 0) {
        memberList = memberList.sublist(0, min(batchSize, memberList.length));
      }

      for (final uid in memberList) {
        final user = await UserInfoDao().getUserByUid(uid);
        // print("$uid, $user");

        if (user == null) {
          continue;
        }
        users.add(user);
      }
    }

    if (users.isNotEmpty) {
      users.sort(((a, b) {
        return a.userInfo.name.compareTo(b.userInfo.name);
      }));
      return users;
    }
    return null;
  }

  Future<int> deleteGroupByGid(int gid) async {
    try {
      return await db.delete(GroupInfoM.F_tableName,
          where: "${GroupInfoM.F_gid} = ?", whereArgs: [gid]).then((value) {
        App.logger.info("Channel $gid has been deleted.");
        return value;
      });
    } catch (e) {
      App.logger.severe(e);
      return -1;
    }
  }

  /// Empty pinned status of GroupInfoM.
  ///
  /// If [ssePinnedGidList] is not empty, the pinned status of GroupInfoM whose uid is
  /// not in [ssePinnedGidList] will be cleared.
  /// [ssePinnedGidList] is the list of uid which is pushed by server, that is, the
  /// channel with a valid [pinnedAt].
  // Future<bool> emptyUnpushedPinnedStatus(List<int> ssePinnedGidList) async {
  //   final ssePinnedGidSet = Set<int>.from(ssePinnedGidList);

  //   final localPinnedGids = (await getChannelList())
  //           ?.where((element) => element.properties.pinnedAt != null)
  //           .map((e) => e.gid)
  //           .toList() ??
  //       [];

  //   final complementGidList = localPinnedGids
  //       .where((element) => !ssePinnedGidSet.contains(element))
  //       .toList();

  //   for (final gid in complementGidList) {
  //     await updateProperties(gid, pinnedAt: -1);
  //   }

  //   return true;
  // }
}
