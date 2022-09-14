import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reaction_info.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ReactionInfo extends Equatable {
  // final int mid;
  // final int localMid;
  final int fromUid;
  final String reaction;
  final int createdAt;

  // ReactionInfo(
  //     this.mid, this.localMid, this.fromUid, this.reaction, this.createdAt);

  const ReactionInfo(this.fromUid, this.reaction, this.createdAt);

  factory ReactionInfo.fromJson(Map<String, dynamic> json) =>
      _$ReactionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReactionInfoToJson(this);

  @override
  List<Object?> get props => [reaction, fromUid];

  @override
  bool? get stringify => true;
}
