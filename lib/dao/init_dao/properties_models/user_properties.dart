/*

uid*	integer($int64)
email*	string
name*	string
gender*	integer($int32)
language*	string($language)
}

*/

import 'package:json_annotation/json_annotation.dart';

part 'user_properties.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProperties {
  late int burnAfterReadSecond;
  late bool enableMute = false;
  late int? muteExpiresAt;

  /// -1 if not initialized.
  late int readIndex;
  late String draft;

  UserProperties(
    this.burnAfterReadSecond,
    this.enableMute,
    this.muteExpiresAt,
    this.readIndex,
    this.draft,
  );

  UserProperties.update({
    int? burnAfterReadSecond,
    bool? enableMute,
    this.muteExpiresAt,
    int? readIndex,
    String? draft,
  }) {
    this.burnAfterReadSecond = burnAfterReadSecond ?? 0;

    this.enableMute = enableMute ?? false;

    this.readIndex = readIndex ?? -1;

    this.draft = draft ?? "";
  }

  factory UserProperties.fromJson(Map<String, dynamic> json) =>
      _$UserPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPropertiesToJson(this);
}
