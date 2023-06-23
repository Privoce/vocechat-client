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
  final List<BurnAfterReadingGroup> burnAfterReadingGroups;
  final List<BurnAfterReadingUser> burnAfterReadingUsers;
  final List<MuteGroup> muteGroups;
  final List<MuteUser> muteUsers;
  final List<PinnedChat> pinnedChats;
  final List<ReadIndexGroup> readIndexGroups;
  final List<ReadIndexUser> readIndexUsers;

  UserSettings({
    required this.burnAfterReadingGroups,
    required this.burnAfterReadingUsers,
    required this.muteGroups,
    required this.muteUsers,
    required this.pinnedChats,
    required this.readIndexGroups,
    required this.readIndexUsers,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);
}
