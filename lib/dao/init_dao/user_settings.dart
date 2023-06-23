// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/user_settings.dart';

class UserSettingsM with M {
  String settings = "";

  UserSettingsM();

  UserSettingsM.item(this.settings, String id, int createdAt) {
    super.id = id;
    super.createdAt = createdAt;
  }

  UserSettingsM.fromUserSettings(UserSettings data) {
    settings = json.encode(data.toJson());
  }

  static UserSettingsM fromMap(Map<String, dynamic> map) {
    UserSettingsM m = UserSettingsM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_settings)) {
      m.settings = map[F_settings];
    }
    if (map.containsKey(F_createdAt)) {
      m.createdAt = map[F_createdAt];
    }

    return m;
  }

  static const F_tableName = 'user_settings';
  static const F_settings = 'settings';
  static const F_createdAt = 'created_at';

  @override
  Map<String, Object> get values => {
        UserSettingsM.F_settings: settings,
        UserSettingsM.F_createdAt: createdAt
      };

  static MMeta meta = MMeta.fromType(UserSettingsM, UserSettingsM.fromMap)
    ..tableName = F_tableName;
}

class UserSettingsDao extends Dao<UserSettingsM> {
  UserSettingsDao() {
    UserSettingsM.meta;
  }

  Future<UserSettingsM> addOrUpdate(UserSettingsM m) async {
    final old = await super.first();
    if (old != null) {
      m.id = old.id;
      await super.update(m);
      App.logger.info("UserSettings updated. ${m.values}");
    } else {
      await super.add(m);
      App.logger.info("UserSettings added. ${m.values}");
    }
    return m;
  }

  Future<UserSettings?> getSettings() async {
    final m = await super.first();
    if (m != null) {
      return UserSettings.fromJson(json.decode(m.settings));
    }
    return null;
  }

  Future<GroupSettings?> getGroupSettings(int gid) async {
    final m = await super.first();
    if (m != null) {
      final settings = UserSettings.fromJson(json.decode(m.settings));

      // Burn after read
      final burnAfterReadsGroups = settings.burnAfterReadingGroups;
      // if (burnAfterReadsGroups.con)

      // final groupSettings = settings.groupSettings[gid];
      // if (groupSettings != null) {
      //   return groupSettings;
      // }
    }
    // return GroupSettings(
    //     0, false, false, 0); // default settings if not found in db.
  }
}

class GroupSettings {
  final int burnAfterReadSecond; // in seconds. <=0 means disabled.
  final bool enableMute;
  final bool pinned;
  final int readIndex;

  GroupSettings({
    required this.burnAfterReadSecond,
    required this.enableMute,
    required this.pinned,
    required this.readIndex,
  });
}
