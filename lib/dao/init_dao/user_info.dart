// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';
import 'package:azlistview/azlistview.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:vocechat_client/api/models/user/contact_info.dart';
import 'package:vocechat_client/api/models/user/user_contact.dart';
import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/api/models/user/user_info_update.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:vocechat_client/dao/init_dao/contacts.dart';
import 'package:vocechat_client/dao/init_dao/dm_info.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_properties.dart';
import 'package:sqflite/utils/utils.dart';
import 'package:vocechat_client/dao/org_dao/userdb.dart';
import 'package:vocechat_client/globals.dart';

class UserInfoM extends ISuspensionBean with M, EquatableMixin {
  int uid = -1;
  String info = "";
  String _properties = "";

  // Following properties in [contacts] table.
  String contactStatusStr = ContactStatus.none.name;
  ContactStatus get contactStatus {
    return ContactStatus.values.firstWhere((e) => e.name == contactStatusStr,
        orElse: () => ContactStatus.none);
  }

  int contactUpdatedAt = 0;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    //data['uid'] = this.uid;
    data['info'] = info;
    //data['avatarBytes'] = this.avatarBytes;
    // data['photo'] = avatarBytes;
    return data;
  }

  String get initial {
    try {
      String initial;

      initial = PinyinHelper.getFirstWordPinyin(userInfo.name)
          .substring(0, 1)
          .toUpperCase();

      if (!RegExp("[A-Z]").hasMatch(initial)) {
        initial = "#";
      }
      return initial;
    } catch (e) {
      App.logger.severe(e);
      return "#";
    }
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

  bool get deleted => uid == -1;

  String get propertiesStr => _properties;

  UserInfoUpdate get userInfoUpdate {
    return UserInfoUpdate.fromJson(jsonDecode(info));
  }

  UserInfoM();

  UserInfoM.item(
    this.uid,
    this.info,
    this._properties,
  );

  UserInfoM.fromUserInfo(
    UserInfo userInfo,
    this._properties,
  ) {
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
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }

    return m;
  }

  static const F_tableName = 'user_info';
  static const F_uid = 'uid';
  static const F_info = 'info';
  static const F_properties = 'properties';
  static const F_createdAt = 'created_at';

  @override
  Map<String, Object> get values => {
        UserInfoM.F_uid: uid,
        UserInfoM.F_info: info,
        UserInfoM.F_properties: _properties,
        UserInfoM.F_createdAt: createdAt,
      };

  static MMeta meta = MMeta.fromType(UserInfoM, UserInfoM.fromMap)
    ..tableName = F_tableName;

  @override
  String getSuspensionTag() => initial;

  @override
  List<Object?> get props => [
        uid,
        info,
        _properties,
        // createdAt,
        contactStatusStr,
        contactUpdatedAt
      ];
}

class UserInfoDao extends Dao<UserInfoM> {
  UserInfoDao() {
    UserInfoM.meta;
  }

  /// Add or update UserInfoM. This will not update [ContactInfo] fields.
  /// But it will add [ContactInfo] fields if no previous records found.
  ///
  /// UserInfoM extends EquatableMixin and it can be compared by
  /// [uid], [info]
  ///
  /// When these fields are the same, the UserInfoM will not be updated.
  Future<UserInfoM> addOrUpdate(UserInfoM m) async {
    UserInfoM? old =
        await first(where: '${UserInfoM.F_uid} = ?', whereArgs: [m.uid]);
    if (old != null) {
      if (old == m) return old;

      m.id = old.id;
      m.createdAt = old.createdAt;

      await super.update(m);

      App.logger.info("UserInfoM updated. ${m.uid}");
    } else {
      await super.add(m);
      App.logger.info("UserInfoM added. ${m.uid}");
    }

    final contactDao = ContactDao();
    final contactInfo = await contactDao.getContactInfo(m.uid);
    if (contactInfo != null) {
      m.contactStatusStr = contactInfo.status;
      m.contactUpdatedAt = contactInfo.updatedAt;
    }

    return m;
  }

  /// Update properties of UserInfoM.
  ///
  /// To cancel [pinnedAt], set it to 0 or -1.
  Future<UserInfoM?> updateProperties(int uid, {String? draft}) async {
    UserInfoM? old =
        await first(where: '${UserInfoM.F_uid} = ?', whereArgs: [uid]);
    if (old != null) {
      UserProperties oldProperties = old.properties;

      if (draft != null) {
        oldProperties.draft = draft;
      }

      old._properties = json.encode(oldProperties);
      await super.update(old);

      final contactDao = ContactDao();
      final contactInfo = await contactDao.getContactInfo(uid);
      if (contactInfo != null) {
        old.contactStatusStr = contactInfo.status;
        old.contactUpdatedAt = contactInfo.updatedAt;
      }

      App.logger.info("UserInfoM properties updated. uid:$uid, draft: $draft");
    }

    return old;
  }

  /// Get the contact list.
  ///
  /// This function automatically checks whether to return the full contact list
  /// (everyone in the server), or just the 'friends' list.
  ///
  /// Check criteria:
  /// if contact mode is disabled in server settings,
  /// || if the current user is an admin.
  Future<List<UserInfoM>?> getUserList() async {
    final contactVerificationEnabled =
        App.app.chatServerM.properties.commonInfo?.contactVerificationEnable ==
            true;
    final isAdmin = App.app.userDb?.userInfo.isAdmin == true;

    final shouldGetAllUsers = !contactVerificationEnabled || isAdmin;

    List<UserInfoM> userList = [];

    String orderBy = "${UserInfoM.F_uid} ASC";
    final contactDao = ContactDao();

    if (shouldGetAllUsers) {
      userList = await super.list(orderBy: orderBy);
    } else {
      // the following users should be included:
      // 1. admins
      // 2. contacts of mine
      // Please note that these user might overlap. [uidSet] is introduced to
      // avoid duplication.
      final uidSet = <int>{};
      final contactList = await contactDao.list();

      for (var contact in contactList) {
        final user = await getUserByUid(contact.uid);
        if (user != null) {
          user.contactStatusStr = contact.status;
          user.contactUpdatedAt = contact.updatedAt;
          uidSet.add(user.uid);
          userList.add(user);
        }
      }

      // Add myself's userInfoM, together with contact status, to the list,
      // as it is not in the contact list.
      final myselfInfoM = await getUserByUid(App.app.userDb!.userInfo.uid);
      if (myselfInfoM != null && !uidSet.contains(myselfInfoM.uid)) {
        myselfInfoM.contactStatusStr = ContactStatus.added.name;
        myselfInfoM.contactUpdatedAt = DateTime.now().millisecondsSinceEpoch;
        uidSet.add(myselfInfoM.uid);
        userList.add(myselfInfoM);
      }

      // Add admins
      const sqlStr =
          "SELECT * FROM ${UserInfoM.F_tableName} WHERE json_extract(${UserInfoM.F_info}, '\$.isAdmin') = 1";
      final records = await db.rawQuery(sqlStr);
      if (records.isNotEmpty) {
        final admins = records.map((e) => UserInfoM.fromMap(e)).toList();
        for (var admin in admins) {
          if (!uidSet.contains(admin.uid)) {
            userList.add(admin);
            uidSet.add(admin.uid);
          }
        }
      }
    }

    return userList;
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
    final user =
        await super.first(where: "${UserInfoM.F_uid} = ?", whereArgs: [uid]);
    if (user != null) {
      final contactDao = ContactDao();
      final contactInfo = await contactDao.getContactInfo(user.uid);
      if (contactInfo != null) {
        user.contactStatusStr = contactInfo.status;
        user.contactUpdatedAt = contactInfo.updatedAt;
      }
    }

    return user;
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

      final contactDao = ContactDao();

      for (var user in result) {
        final contactInfo = await contactDao.getContactInfo(user.uid);
        if (contactInfo != null) {
          user.contactStatusStr = contactInfo.status;
          user.contactUpdatedAt = contactInfo.updatedAt;
        }
      }

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
}
