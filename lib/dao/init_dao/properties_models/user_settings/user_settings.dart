import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/burn_after_reading_group.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/burn_after_reading_user.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/mute_group.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/mute_user.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/pinned_chat.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/read_index_group.dart';
import 'package:vocechat_client/dao/init_dao/properties_models/user_settings/read_index_user.dart';

part 'user_settings.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserSettings {
  /// {gid: expiresIn(seconds)}
  Map<int, int>? burnAfterReadingGroups;

  /// {uid: expiresIn(seconds)}
  Map<int, int>? burnAfterReadingUsers;

  /// {gid: expiredAt(optional seconds)}
  Map<int, int?>? muteGroups;

  /// {uid: expiredAt(optional seconds)}
  Map<int, int?>? muteUsers;

  List<int>? pinnedGroups;
  List<int>? pinnedUsers;

  Map<int, int>? readIndexGroups;
  Map<int, int>? readIndexUsers;

  UserSettings({
    this.burnAfterReadingGroups,
    this.burnAfterReadingUsers,
    this.muteGroups,
    this.muteUsers,
    this.pinnedGroups,
    this.pinnedUsers,
    this.readIndexGroups,
    this.readIndexUsers,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);
}
