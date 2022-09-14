import 'package:json_annotation/json_annotation.dart';

part 'msg_reaction.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MsgReaction {
  final int mid;

  /// MsgReactionDelete, MsgReactionEdit, MsgReactionLike
  final Map<String, dynamic> detail;
  final String type;

  MsgReaction(
      {required this.mid, required this.detail, this.type = 'reaction'});

  factory MsgReaction.fromJson(Map<String, dynamic> json) =>
      _$MsgReactionFromJson(json);

  Map<String, dynamic> toJson() => _$MsgReactionToJson(this);
}
