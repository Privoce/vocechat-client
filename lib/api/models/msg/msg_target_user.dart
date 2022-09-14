import 'package:json_annotation/json_annotation.dart';

part 'msg_target_user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MsgTargetUser {
  final int uid;
  MsgTargetUser(this.uid);

  factory MsgTargetUser.fromJson(Map<String, dynamic> json) =>
      _$MsgTargetUserFromJson(json);

  Map<String, dynamic> toJson() => _$MsgTargetUserToJson(this);
}
