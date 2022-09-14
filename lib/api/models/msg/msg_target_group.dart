import 'package:json_annotation/json_annotation.dart';

part 'msg_target_group.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MsgTargetGroup {
  final int gid;
  MsgTargetGroup(this.gid);

  factory MsgTargetGroup.fromJson(Map<String, dynamic> json) =>
      _$MsgTargetGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MsgTargetGroupToJson(this);
}
