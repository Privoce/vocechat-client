import 'package:json_annotation/json_annotation.dart';

part 'chat_msg.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatMsg {
  int mid;
  final int fromUid;
  final int createdAt;

  /// MsgTargetGroup or MsgTargetUser
  final Map<String, dynamic> target;

  /// MsgNormal or MsgReaction
  final Map<String, dynamic> detail;

  ChatMsg(
      {required this.mid,
      required this.fromUid,
      required this.createdAt,
      required this.target,
      required this.detail});

  factory ChatMsg.fromJson(Map<String, dynamic> json) =>
      _$ChatMsgFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMsgToJson(this);
}
