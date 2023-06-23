import 'package:json_annotation/json_annotation.dart';

part 'pinned_chat.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PinnedChat {
  final Map<String, int> target;
  final int updatedAt;

  PinnedChat({
    required this.target,
    required this.updatedAt,
  });

  factory PinnedChat.fromJson(Map<String, dynamic> json) =>
      _$PinnedChatFromJson(json);

  Map<String, dynamic> toJson() => _$PinnedChatToJson(this);
}
