import 'package:json_annotation/json_annotation.dart';

part 'msg_normal.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MsgNormal {
  final Map<String, dynamic>? properties;
  String contentType;
  String content;
  final int? expiresIn;
  final String type;

  MsgNormal(
      {this.properties,
      required this.contentType,
      required this.content,
      this.expiresIn,
      this.type = 'normal'});

  factory MsgNormal.fromJson(Map<String, dynamic> json) =>
      _$MsgNormalFromJson(json);

  Map<String, dynamic> toJson() => _$MsgNormalToJson(this);
}
