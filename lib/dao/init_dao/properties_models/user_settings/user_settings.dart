// ignore_for_file: must_be_immutable

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_settings.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserSettings extends Equatable {
  /// {gid: expiresIn(seconds)}
  Map<int, int>? burnAfterReadingGroups;

  /// {uid: expiresIn(seconds)}
  Map<int, int>? burnAfterReadingUsers;

  /// {gid: expiredAt(optional seconds)}
  Map<int, int?>? muteGroups;

  /// {uid: expiredAt(optional seconds)}
  Map<int, int?>? muteUsers;

  Map<int, int>? pinnedGroups;
  Map<int, int>? pinnedUsers;

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

  @override
  List<Object?> get props => [
        burnAfterReadingGroups,
        burnAfterReadingUsers,
        muteGroups,
        muteUsers,
        pinnedGroups,
        pinnedUsers,
        readIndexGroups,
        readIndexUsers
      ];
}
