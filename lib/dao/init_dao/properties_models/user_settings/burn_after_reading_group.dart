import 'package:json_annotation/json_annotation.dart';

part 'burn_after_reading_group.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BurnAfterReadingGroup {
  final int gid;
  final int expiresIn;

  BurnAfterReadingGroup({
    required this.gid,
    required this.expiresIn,
  });

  factory BurnAfterReadingGroup.fromJson(Map<String, dynamic> json) =>
      _$BurnAfterReadingGroupFromJson(json);

  Map<String, dynamic> toJson() => _$BurnAfterReadingGroupToJson(this);
}
