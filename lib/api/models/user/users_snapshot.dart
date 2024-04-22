/*

uid*	integer($int64)
email*	string
name*	string
gender*	integer($int32)
language*	string($language)
}

*/

import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/api/models/user/old_user_info.dart';

part 'users_snapshot.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UsersSnapshot {
  final List<OldUserInfo>? users;
  final int version;

  UsersSnapshot({required this.version, this.users});

  factory UsersSnapshot.fromJson(Map<String, dynamic> json) =>
      _$UsersSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$UsersSnapshotToJson(this);
}
