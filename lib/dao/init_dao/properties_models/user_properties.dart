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
  // late int burnAfterReadSecond;
  // late bool enableMute = false;
  // late int? muteExpiresAt;

  /// -1 if not initialized.
  // late int readIndex;
  late String draft;

  /// Indicates whether the user is pinned.
  ///
  /// If the user is pinned, the pinnedAt field will be set to the time provided
  /// by the server. Otherwise, the pinnedAt field will be null.
  late int? pinnedAt;

  UserProperties(
      // this.burnAfterReadSecond, this.enableMute, this.muteExpiresAt,
      // this.readIndex,
      this.draft,
      this.pinnedAt);

  UserProperties.update(
      {
      //   int? burnAfterReadSecond,
      // bool? enableMute,
      // this.muteExpiresAt,
      // int? readIndex,
      String? draft,
      this.pinnedAt}) {
    // this.burnAfterReadSecond = burnAfterReadSecond ?? 0;

    // this.enableMute = enableMute ?? false;

    // this.readIndex = readIndex ?? -1;

    this.draft = draft ?? "";
  }

  factory UserProperties.fromJson(Map<String, dynamic> json) =>
      _$UserPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPropertiesToJson(this);
}
