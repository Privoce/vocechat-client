// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:vocechat_client/api/models/group/group_info.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/pinned_msg.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/group_properties.dart';
import 'package:vocechat_client/dao/init_dao/user_info.dart';

class GroupInfoM with M {
  int gid = -1;
  String lastLocalMid = "";
  String info = "";
  // Uint8List avatar = Uint8List(0);
  String _properties = "";
  int isPublic = 1;
  int isActive = 1;
  int updatedAt = 0;

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
      this.isPublic, this.isActive, this.updatedAt);

  GroupInfoM.fromGroupInfo(
    GroupInfo groupInfo,
    bool isActive,
  ) {
    gid = groupInfo.gid;
    info = jsonEncode(groupInfo.toJson());
    isPublic = groupInfo.isPublic ? 1 : 0;
    this.isActive = isActive ? 1 : 0;
    // updatedAt = DateTime.now().millisecondsSinceEpoch;

    // if (avatar != null) {
    //   this.avatar = avatar;
    // }
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
    // if (map.containsKey(F_avatar)) {
    //   m.avatar = map[F_avatar];
    // }
    if (map.containsKey(F_properties)) {
      m._properties = map[F_properties];
    }
    if (map.containsKey(F_isPublic)) {
      m.isPublic = map[F_isPublic];
    }
    if (map.containsKey(F_isActive)) {
      m.isActive = map[F_isActive];
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
  // static const F_avatar = 'avatar';
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
        // GroupInfoM.F_avatar: avatar,
        GroupInfoM.F_properties: _properties,
        GroupInfoM.F_isPublic: isPublic,
        GroupInfoM.F_isActive: isActive,
        GroupInfoM.F_createdAt: createdAt,
        GroupInfoM.F_updatedAt: updatedAt,
      };

  static MMeta meta = MMeta.fromType(GroupInfoM, GroupInfoM.fromMap)
    ..tableName = F_tableName;
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
        // m.avatar = old.avatar;
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
        old.isPublic = isPublic ? 1 : 0;
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

  Future<GroupInfoM?> updateProperties(int gid,
      {int? burnAfterReadSecond,
      bool? enableMute,
      int? muteExpiresAt,
      int? readIndex,
      String? draft}) async {
    GroupInfoM? old =
        await first(where: '${GroupInfoM.F_gid} = ?', whereArgs: [gid]);
    if (old != null) {
      GroupProperties oldProperties = old.properties;
      if (burnAfterReadSecond != null) {
        oldProperties.burnAfterReadSecond = burnAfterReadSecond;
      }

      if (enableMute != null) {
        oldProperties.enableMute = enableMute;
      }

      if (muteExpiresAt != null) {
        old.properties.muteExpiresAt = muteExpiresAt;
      }

      if (readIndex != null) {
        if (oldProperties.readIndex == -1) {
          oldProperties.readIndex = readIndex;
        } else {
          oldProperties.readIndex = max(oldProperties.readIndex, readIndex);
        }
      }

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
      old.isActive = 0;
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

    if (group.isPublic == 1) {
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

  // Future<ChatServerM?> currentServer() async {
  //   ChatServerM? chatServer = await get(await OrgSettingDao.dao.getCurrentServerId());
  //   return chatServer;
  // }

  // Future<void> updateCompanyFromServer(ChatServerM m) async {
  //   ChatClient chat = createChatClient(createClientChannel(m.tls.toTrue(), m.url, m.port));
  //   Company res = await chat.companyGet(EmptyReq(token: ""));
  //   m.serverName = res.name;
  //   m.logo = imageWebStringToBytes(res.logo);
  //   await get(await OrgSettingDao.dao.getCurrentServerId());
  //   return;
  // }
}
