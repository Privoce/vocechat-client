import 'package:json_annotation/json_annotation.dart';

part 'msg_reaction_edit.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MsgReactionEdit {
  final String content;

  MsgReactionEdit(this.content);

  factory MsgReactionEdit.fromJson(Map<String, dynamic> json) =>
      _$MsgReactionEditFromJson(json);

  Map<String, dynamic> toJson() => _$MsgReactionEditToJson(this);
}
