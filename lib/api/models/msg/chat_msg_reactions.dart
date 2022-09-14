import 'package:json_annotation/json_annotation.dart';

part 'chat_msg_reactions.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatMsgReactions {
  final List<Map<int, String>> reactions;

  ChatMsgReactions(this.reactions);

  factory ChatMsgReactions.fromJson(Map<String, dynamic> json) =>
      _$ChatMsgReactionsFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMsgReactionsToJson(this);
}
