// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:vocechat_client/api/models/user/user_info.dart';
import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:vocechat_client/dao/org_dao/properties_models/userdb_properties.dart';

/// Contains user-specific data.
class UserDbM with M {
  // @override
  // List<Object?> get props => [url];

  /// 用户 id
  int uid = -1;

  /// UserInfo json
  String info = "";

  /// database name
  String dbName = "";

  /// the [chatServerId] the user is in.
  String chatServerId = "";

  int createdAt = 0;

  int updatedAt = 0;

  /// token
  String token = "";

  /// The token to refresh token.
  String refreshToken = "";

  int expiredIn = 0;

  int loggedIn = 0;

  int usersVersion = -1;

  Uint8List avatarBytes = Uint8List(0);

  String _properties = "";

  UserInfo get userInfo {
    return UserInfo.fromJson(jsonDecode(info));
  }

  UserDbProperties get properties {
    return UserDbProperties.fromJson(jsonDecode(_properties));
  }

  set properties(UserDbProperties p) {
    _properties = jsonEncode(p);
  }

  UserDbM();

  UserDbM.item(
      this.uid,
      this.info,
      this.dbName,
      this.chatServerId,
      this.createdAt,
      this.updatedAt,
      this.token,
      this.refreshToken,
      this.expiredIn,
      this.loggedIn,
      this.usersVersion,
      this.avatarBytes,
      this._properties);

  static UserDbM fromMap(Map<String, dynamic> map) {
    UserDbM m = UserDbM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_uid)) {
      m.uid = map[F_uid];
    }
    if (map.containsKey(F_info)) {
      m.info = map[F_info];
    }
    if (map.containsKey(F_dbName)) {
      m.dbName = map[F_dbName];
    }
    if (map.containsKey(F_chatServerId)) {
      m.chatServerId = map[F_chatServerId];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }
    if (map.containsKey(F_updatedAt)) {
      m.updatedAt = map[F_updatedAt];
    }
    if (map.containsKey(F_token)) {
      m.token = map[F_token];
    }
    if (map.containsKey(F_refreshToken)) {
      m.refreshToken = map[F_refreshToken];
    }
    if (map.containsKey(F_expiredIn)) {
      m.expiredIn = map[F_expiredIn];
    }
    if (map.containsKey(F_loggedIn)) {
      m.loggedIn = map[F_loggedIn];
    }
    if (map.containsKey(F_usersVersion)) {
      m.usersVersion = map[F_usersVersion];
    }
    if (map.containsKey(F_avatarBytes)) {
      m.avatarBytes = map[F_avatarBytes];
    }
    if (map.containsKey(F_properties)) {
      m._properties = map[F_properties];
    }
    return m;
  }

  static const F_tableName = "user_db";
  static const F_uid = "uid";
  static const F_info = "info";
  static const F_dbName = "db_name";
  static const F_chatServerId = "chat_server_id";
  static const F_createdAt = "created_at";
  static const F_updatedAt = "updated_at";
  static const F_token = "token";
  static const F_refreshToken = "refresh_token";
  static const F_expiredIn = "expired_in";
  static const F_loggedIn = "logged_in";
  static const F_usersVersion = "users_version";
  static const F_avatarBytes = "avatar_bytes";
  static const F_properties = "properties";

  @override
  Map<String, Object> get values => {
        UserDbM.F_uid: uid,
        UserDbM.F_info: info,
        UserDbM.F_dbName: dbName,
        UserDbM.F_chatServerId: chatServerId,
        UserDbM.F_createdAt: createdAt,
        UserDbM.F_updatedAt: updatedAt,
        UserDbM.F_token: token,
        UserDbM.F_refreshToken: refreshToken,
        UserDbM.F_expiredIn: expiredIn,
        UserDbM.F_loggedIn: loggedIn,
        UserDbM.F_usersVersion: usersVersion,
        UserDbM.F_avatarBytes: avatarBytes,
        UserDbM.F_properties: _properties
      };

  static MMeta meta = MMeta.fromType(UserDbM, UserDbM.fromMap)
    ..tableName = F_tableName;
}

class UserDbMDao extends OrgDao<UserDbM> {
  static final UserDbMDao dao = UserDbMDao._p();
  final _logger = SimpleLogger();

  UserDbMDao._p() {
    UserDbM.meta;
  }

  /// Use both chat_server_id and uid to define a user.
  Future<UserDbM> addOrUpdate(UserDbM m) async {
    UserDbM? old = await first(
        where: '${UserDbM.F_chatServerId} = ? AND ${UserDbM.F_uid} = ?',
        whereArgs: [m.chatServerId, m.uid]);
    if (old != null) {
      m.id = old.id;
      m.chatServerId = old.chatServerId;
      m.uid = old.uid;
      m.createdAt = old.createdAt;
      m.usersVersion = old.usersVersion;
      await super.update(m);
    } else {
      await super.add(m);
    }
    _logger.info("UserDb saved. Id: ${m.id}");
    return m;
  }

  /// Use both chat_server_id and uid to define a user.
  Future<UserDbM?> updateUserInfo(UserInfo userInfo,
      [Uint8List? avatarBytes]) async {
    if (userInfo.uid != App.app.userDb?.uid) {
      return null;
    }
    final chatServerId = App.app.chatServerM.id;
    final uid = App.app.userDb!.uid;
    UserDbM? old = await first(
        where: '${UserDbM.F_chatServerId} = ? AND ${UserDbM.F_uid} = ?',
        whereArgs: [chatServerId, uid]);
    if (old != null) {
      old.info = jsonEncode(userInfo.toJson());
      if (avatarBytes != null) {
        old.avatarBytes = avatarBytes;
      }
      old.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await super.update(old);
    }
    return old;
  }

  /// Get a list of current users
  ///
  /// Result shown in
  /// 1. createdTs, descending order
  Future<List<UserDbM>?> getList() async {
    String orderBy = "${UserDbM.F_createdAt} DESC";
    return super.list(orderBy: orderBy);
  }

  Future<UserDbM?> getUserDbById(String id) async {
    return super.get(id);
  }

  Future<UserDbM?> getUserDbByUid(int uid) async {
    return first(where: '${UserDbM.F_uid} = ?', whereArgs: [uid]);
  }

  Future<UserDbM> updateAuth(
      String id, String token, String refreshToken, int expiredIn) async {
    UserDbM? old = await get(id);
    if (old != null) {
      old.token = token;
      old.refreshToken = refreshToken;
      old.expiredIn = expiredIn;
      old.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await super.update(old);
      _logger.config(
          "UserDb Auth updated. id:$id, Token:$token, rToken:$refreshToken, exp:$expiredIn");
    } else {
      throw Exception("No matching UserDb found");
    }
    return old;
  }

  Future<UserDbM> updateUsersVersion(String id, int version) async {
    UserDbM? old = await get(id);
    if (old != null) {
      old.usersVersion = version;
      old.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await super.update(old);
      _logger.config("UserDb UsersVersion updated. Version:$version");
    } else {
      throw Exception("No matching UserDb found");
    }
    return old;
  }

  Future<UserDbM> updateWhenLogout(String id) async {
    UserDbM? old = await get(id);
    if (old != null) {
      old.loggedIn = 0;
      old.token = "";
      old.refreshToken = "";
      await super.update(old);
      _logger.config("UserDb LoggedIn => false");
    } else {
      throw Exception("UpdateWhenLogout Failed.");
    }
    return old;
  }
}
