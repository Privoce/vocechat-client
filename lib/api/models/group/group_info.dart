import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/api/models/msg/msg_archive/pinned_msg.dart';

part 'group_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GroupInfo {
  final int gid;
  int? owner;
  String name;
  String? description;
  List<int>? members;
  int avatarUpdatedAt;
  List<PinnedMsg> pinnedMessages;
  bool isPublic;

  GroupInfo(this.gid, this.owner, this.name, this.description, this.members,
      this.isPublic, this.avatarUpdatedAt, this.pinnedMessages);

  factory GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);

  Map<String, dynamic> toJson() => _$GroupInfoToJson(this);
}
