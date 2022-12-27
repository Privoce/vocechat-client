// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/api/models/user/user_info_update.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_properties.dart';
import 'package:sqflite/utils/utils.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';

class UserInfoM extends ISuspensionBean with M {
  int uid = -1;
  String info = "";
  String _properties = "";
  Uint8List avatarBytes = Uint8List(0);
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    //data['uid'] = this.uid;
    data['info'] = info;
    //data['avatarBytes'] = this.avatarBytes;
    data['photo'] = avatarBytes;
    return data;
  }

  String get initial {
    String _initial;

    _initial = PinyinHelper.getFirstWordPinyin(userInfo.name)
        .substring(0, 1)
        .toUpperCase();

    if (!RegExp("[A-Z]").hasMatch(_initial)) {
      _initial = "#";
    }
    return _initial;
  }

  ValueNotifier<bool> onlineNotifier = ValueNotifier(false);

  UserInfo get userInfo {
    return UserInfo.fromJson(jsonDecode(info));
  }

  UserProperties get properties {
    if (_properties.isNotEmpty) {
      return UserProperties.fromJson(json.decode(_properties));
    } else {
      return UserProperties.update();
    }
  }

  UserInfoUpdate get userInfoUpdate {
    return UserInfoUpdate.fromJson(jsonDecode(info));
  }

  UserInfoM();

  UserInfoM.item(this.uid, this.info, this._properties, this.avatarBytes);

  UserInfoM.fromUserInfo(
      UserInfo userInfo, this.avatarBytes, this._properties) {
    uid = userInfo.uid;
    info = jsonEncode(userInfo.toJson());
  }

  UserInfoM.deleted() {
    info = json.encode(UserInfo.deleted());
  }

  static UserInfoM fromMap(Map<String, dynamic> map) {
    UserInfoM m = UserInfoM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_uid)) {
      m.uid = map[F_uid];
    }
    if (map.containsKey(F_info)) {
      m.info = map[F_info];
    }
    if (map.containsKey(F_properties)) {
      m._properties = map[F_properties];
    }
    if (map.containsKey(F_avatar)) {
      m.avatarBytes = map[F_avatar];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }

    return m;
  }

  static const F_tableName = 'user_info';
  static const F_uid = 'uid';
  static const F_info = 'info';
  static const F_properties = 'properties';
  static const F_avatar = 'avatar';
  static const F_createdAt = 'created_at';

  @override
  Map<String, Object> get values => {
        UserInfoM.F_uid: uid,
        UserInfoM.F_info: info,
        UserInfoM.F_properties: _properties,
        UserInfoM.F_avatar: avatarBytes,
        UserInfoM.F_createdAt: createdAt,
      };

  static MMeta meta = MMeta.fromType(UserInfoM, UserInfoM.fromMap)
    ..tableName = F_tableName;

  @override
  String getSuspensionTag() => initial;
}

class UserInfoDao extends Dao<UserInfoM> {
  UserInfoDao() {
    UserInfoM.meta;
  }

  Future<UserInfoM> addOrUpdate(UserInfoM m) async {
    UserInfoM? old =
        await first(where: '${UserInfoM.F_uid} = ?', whereArgs: [m.uid]);
    if (old != null) {
      m.id = old.id;
      m.createdAt = old.createdAt;
      if (m.avatarBytes.isEmpty) {
        m.avatarBytes = old.avatarBytes;
      }
      // m.avatar = old.avatar;
      await super.update(m);

      App.logger.info("UserInfoM updated. ${m.uid}");
    } else {
      await super.add(m);
      App.logger.info("UserInfoM added. ${m.uid}");
    }

    return m;
  }

  Future<UserInfoM?> updateProperties(int uid,
      {int? burnAfterReadSecond,
      bool? enableMute,
      int? muteExpiresAt,
      int? readIndex,
      String? draft}) async {
    UserInfoM? old =
        await first(where: '${UserInfoM.F_uid} = ?', whereArgs: [uid]);
    if (old != null) {
      UserProperties oldProperties = old.properties;
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

  Future<UserInfoM?> updateLanguage(int uid, String languageTag) async {
    UserInfoM? old =
        await first(where: '${UserInfoM.F_uid} = ?', whereArgs: [uid]);
    if (old != null) {
      UserInfo userInfo = old.userInfo;
      userInfo.language = languageTag;
      old.info = jsonEncode(userInfo);

      await super.update(old);

      await UserDbMDao.dao.updateUserInfo(userInfo);
    }
    return old;
  }

  /// Get a list of Users in UserInfo
  ///
  /// Result shown in
  /// uid, ascending order
  Future<List<UserInfoM>?> getUserList() async {
    String orderBy = "${UserInfoM.F_uid} ASC";
    return super.list(orderBy: orderBy);
  }

  Future<int> getUserCount() async {
    String sqlStr = "SELECT COUNT(*) FROM ${UserInfoM.F_tableName}";
    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      return firstIntValue(records)!;
    }
    return 0;
  }

  Future<UserInfoM?> getUserByUid(int uid) async {
    return super.first(where: "${UserInfoM.F_uid} = ?", whereArgs: [uid]);
  }

  Future<List<UserInfoM>?> getUsersWithDraft() async {
    String sqlStr =
        "SELECT * FROM ${UserInfoM.F_tableName} WHERE json_extract(json(IIF(${UserInfoM.F_properties} <> '',${UserInfoM.F_properties}, NULL)) , '\$.draft') != ''";
    // String sqlStr =
    // "SELECT * FROM ${UserInfoM.F_tableName} WHERE json_extract(${UserInfoM.F_properties} , '\$.draft') != ''";

    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final result = records.map((e) => UserInfoM.fromMap(e)).toList();
      return result;
    }
    return null;
  }

  Future<int> removeByUid(int uid) async {
    MMeta meta = mMetas[UserInfoM]!;
    int count = await db.delete(meta.tableName,
        where: '${UserInfoM.F_uid} = ?', whereArgs: [uid]);
    return count;
  }

  Future<List<UserInfoM>?> getUsersMatched(String keyword) async {
    String sqlStr =
        "SELECT * FROM ${UserInfoM.F_tableName} WHERE json_extract(${UserInfoM.F_info}, '\$.name') LIKE '%$keyword%' OR json_extract(${UserInfoM.F_info}, '\$.email') LIKE '%$keyword%'";

    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final result = records.map((e) => UserInfoM.fromMap(e)).toList();
      return result;
    }
    return null;
  }

  Future<List<UserInfoM>?> getPublicChannelMatched(String input) async {
    String sqlStr =
        "SELECT * FROM ${UserInfoM.F_tableName} WHERE json_extract(${UserInfoM.F_info}, '\$.name') LIKE '%$input%'";

    List<Map<String, Object?>> records = await db.rawQuery(sqlStr);
    if (records.isNotEmpty) {
      final result = records.map((e) => UserInfoM.fromMap(e)).toList();
      return result;
    }
    return null;
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
