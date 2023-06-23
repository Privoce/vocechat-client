import 'package:json_annotation/json_annotation.dart';

part 'mute_group.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MuteGroup {
  final int gid;
  final int? expiredAt;

  MuteGroup({
    required this.gid,
    this.expiredAt,
  });

  factory MuteGroup.fromJson(Map<String, dynamic> json) =>
      _$MuteGroupFromJson(json);

  Map<String, dynamic> toJson() => _$MuteGroupToJson(this);
}
