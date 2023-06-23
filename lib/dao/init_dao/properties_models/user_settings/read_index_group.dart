import 'package:json_annotation/json_annotation.dart';

part 'read_index_group.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ReadIndexGroup {
  final int gid;
  final int mid;

  ReadIndexGroup({
    required this.gid,
    required this.mid,
  });

  factory ReadIndexGroup.fromJson(Map<String, dynamic> json) =>
      _$ReadIndexGroupFromJson(json);

  Map<String, dynamic> toJson() => _$ReadIndexGroupToJson(this);
}
