import 'package:json_annotation/json_annotation.dart';

part 'group_properties.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class GroupProperties {
  late String draft;

  GroupProperties(
    this.draft,
  );

  GroupProperties.update({
    String? draft,
  }) {
    this.draft = draft ?? "";
  }

  factory GroupProperties.fromJson(Map<String, dynamic> json) =>
      _$GroupPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$GroupPropertiesToJson(this);
}
