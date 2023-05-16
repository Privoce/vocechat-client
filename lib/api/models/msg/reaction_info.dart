import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reaction_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ReactionInfo extends Equatable {
  final int fromUid;
  final String emoji;
  final int createdAt;

  const ReactionInfo(
      {required this.fromUid, required this.emoji, required this.createdAt});

  factory ReactionInfo.fromJson(Map<String, dynamic> json) =>
      _$ReactionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReactionInfoToJson(this);

  @override
  List<Object?> get props => [emoji, fromUid];

  @override
  bool? get stringify => true;
}
