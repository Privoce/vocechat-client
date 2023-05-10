import 'package:json_annotation/json_annotation.dart';

part 'msg_reply.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MsgReply {
  final int mid;
  final Map<String, dynamic>? properties;
  final String contentType;
  final String content;
  final int? expiresIn;
  final String type;

  MsgReply(
      {required this.mid,
      required this.contentType,
      required this.content,
      this.properties,
      this.expiresIn,
      this.type = 'reply'});

  factory MsgReply.fromJson(Map<String, dynamic> json) =>
      _$MsgReplyFromJson(json);

  Map<String, dynamic> toJson() => _$MsgReplyToJson(this);
}
