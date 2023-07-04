// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:vocechat_client/app.dart';
import 'package:vocechat_client/dao/dao.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/user_settings.dart';

class UserSettingsM with M {
  String _settings = "";

  UserSettingsM();

  UserSettingsM.item(this._settings, String id, int createdAt) {
    super.id = id;
    super.createdAt = createdAt;
  }

  UserSettingsM.fromUserSettings(UserSettings data) {
    _settings = json.encode(data.toJson());
  }

  UserSettings get settings => UserSettings.fromJson(json.decode(_settings));

  static UserSettingsM fromMap(Map<String, dynamic> map) {
    UserSettingsM m = UserSettingsM();
    if (map.containsKey(M.ID)) {
      m.id = map[M.ID];
    }
    if (map.containsKey(F_settings)) {
      m._settings = map[F_settings];
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
        UserSettingsM.F_settings: _settings,
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
      return UserSettings.fromJson(json.decode(m._settings));
    }
    return null;
  }

  Future<GroupSettings?> getGroupSettings(int gid) async {
    final m = await super.first();
    if (m != null) {
      final settings = UserSettings.fromJson(json.decode(m._settings));

      // Burn after read
      final burnAfterReadsGroups = settings.burnAfterReadingGroups;
      final muteGroups = settings.muteGroups;
      final pinnedGroups = settings.pinnedGroups;
      final readIndexGroups = settings.readIndexGroups;

      final burnAfterReadSecond = burnAfterReadsGroups?[gid] ?? 0;
      // final muteExpiredAt = muteGroups?[gid] ?? 0;
      final pinnedAt = pinnedGroups?[gid] ?? 0;
      final enableMute = muteGroups?.containsKey(gid) ?? false;
      final readIndex = readIndexGroups?[gid] ?? 0;

      return GroupSettings(
          burnAfterReadSecond: burnAfterReadSecond,
          enableMute: enableMute,
          pinnedAt: pinnedAt,
          readIndex: readIndex);
    }
    return null;
  }

  Future<DmSettings?> getDmSettings(int uid) async {
    final m = await super.first();
    if (m != null) {
      final settings = UserSettings.fromJson(json.decode(m._settings));

      // Burn after read
      final burnAfterReadsDms = settings.burnAfterReadingUsers;
      final muteDms = settings.muteUsers;
      final pinnedDms = settings.pinnedUsers;
      final readIndexDms = settings.readIndexUsers;

      final burnAfterReadSecond = burnAfterReadsDms?[uid] ?? 0;
      // final muteExpiredAt = muteDms?[uid] ?? 0;
      final enableMute = muteDms?.containsKey(uid) ?? false;
      final pinnedAt = pinnedDms?[uid] ?? 0;
      final readIndex = readIndexDms?[uid] ?? 0;

      return DmSettings(
          burnAfterReadSecond: burnAfterReadSecond,
          enableMute: enableMute,
          pinnedAt: pinnedAt,
          readIndex: readIndex);
    }
    return null;
  }

  /// Updates group settings by [gid].
  ///
  /// If no local settings, returns null.
  Future<UserSettings?> updateGroupSettings(int gid,
      {int? burnAfterReadSecond,
      int? muteExpiredAt,
      bool? mute,
      int? pinnedAt,
      int? readIndex}) async {
    final m = await super.first();
    if (m != null) {
      final settings = UserSettings.fromJson(json.decode(m._settings));

      if (burnAfterReadSecond != null) {
        settings.burnAfterReadingGroups?[gid] = burnAfterReadSecond;
      }

      // Must check != null first, as update data does not contain all properties.
      if (muteExpiredAt != null) {
        if (muteExpiredAt > 0) {
          settings.muteGroups?.addAll({gid: muteExpiredAt});
        } else {
          settings.muteGroups?.remove(gid);
        }
      }

      if (mute != null) {
        if (mute) {
          settings.muteGroups?.addAll({gid: null});
        } else {
          settings.muteGroups?.remove(gid);
        }
      }

      if (pinnedAt != null) {
        if (pinnedAt > 0) {
          settings.pinnedGroups?.addAll({gid: pinnedAt});
        } else {
          settings.pinnedGroups?.remove(gid);
        }
      }

      if (readIndex != null) {
        settings.readIndexGroups?[gid] = readIndex;
      }

      m._settings = json.encode(settings.toJson());
      await super.update(m);
      App.logger.info("UserSettings updated. ${m.values}");
      return m.settings;
    }
    return null;
  }

  /// Updates dm settings by [dmUid].
  ///
  /// If no local settings, returns null.
  Future<UserSettings?> updateDmSettings(int dmUid,
      {int? burnAfterReadSecond,
      int? muteExpiredAt,
      bool? mute,
      int? pinnedAt,
      int? readIndex}) async {
    final m = await super.first();
    if (m != null) {
      final settings = UserSettings.fromJson(json.decode(m._settings));

      if (burnAfterReadSecond != null) {
        settings.burnAfterReadingUsers?[dmUid] = burnAfterReadSecond;
      }

      if (muteExpiredAt != null) {
        if (muteExpiredAt > 0) {
          settings.muteUsers?[dmUid] = muteExpiredAt;
        } else {
          settings.muteUsers?.remove(dmUid);
        }
      }

      if (mute != null) {
        if (mute) {
          settings.muteUsers?.addAll({dmUid: null});
        } else {
          settings.muteUsers?.remove(dmUid);
        }
      }

      if (pinnedAt != null) {
        if (pinnedAt > 0) {
          settings.pinnedUsers?.addAll({dmUid: pinnedAt});
        } else {
          settings.pinnedUsers?.remove(dmUid);
        }
      }

      if (readIndex != null) {
        settings.readIndexUsers?[dmUid] = readIndex;
      }

      m._settings = json.encode(settings.toJson());
      await super.update(m);
      App.logger.info("UserSettings updated. ${m.values}");
      return m.settings;
    }
    return null;
  }
}

class GroupSettings {
  final int burnAfterReadSecond; // in seconds. <=0 means disabled.
  final bool enableMute;
  final int pinnedAt;
  final int readIndex;

  GroupSettings({
    required this.burnAfterReadSecond,
    required this.enableMute,
    required this.pinnedAt,
    required this.readIndex,
  });

  static GroupSettings fromUserSettings(UserSettings settings, int gid) {
    final burnAfterReadsGroups = settings.burnAfterReadingGroups;
    final muteGroups = settings.muteGroups;
    final pinnedGroups = settings.pinnedGroups;
    final readIndexGroups = settings.readIndexGroups;

    final burnAfterReadSecond = burnAfterReadsGroups?[gid] ?? 0;
    final enableMute = muteGroups?.containsKey(gid) ?? false;
    final pinnedAt = pinnedGroups?[gid] ?? 0;
    final readIndex = readIndexGroups?[gid] ?? 0;

    return GroupSettings(
        burnAfterReadSecond: burnAfterReadSecond,
        enableMute: enableMute,
        pinnedAt: pinnedAt,
        readIndex: readIndex);
  }
}

class DmSettings {
  final int burnAfterReadSecond; // in seconds. <=0 means disabled.
  final bool enableMute;
  final int pinnedAt;
  final int readIndex;

  DmSettings({
    required this.burnAfterReadSecond,
    required this.enableMute,
    required this.pinnedAt,
    required this.readIndex,
  });

  static DmSettings fromUserSettings(UserSettings settings, int uid) {
    final burnAfterReadsUsers = settings.burnAfterReadingUsers;
    final muteUsers = settings.muteUsers;
    final pinnedUsers = settings.pinnedUsers;
    final readIndexUsers = settings.readIndexUsers;

    final burnAfterReadSecond = burnAfterReadsUsers?[uid] ?? 0;
    final enableMute = muteUsers?.containsKey(uid) ?? false;
    final pinnedAt = pinnedUsers?[uid] ?? 0;
    final readIndex = readIndexUsers?[uid] ?? 0;

    return DmSettings(
        burnAfterReadSecond: burnAfterReadSecond,
        enableMute: enableMute,
        pinnedAt: pinnedAt,
        readIndex: readIndex);
  }
}
