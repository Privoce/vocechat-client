import 'package:json_annotation/json_annotation.dart';

part 'user_properties.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProperties {
  late String draft;

  UserProperties(
    this.draft,
  );

  UserProperties.update({
    String? draft,
  }) {
    this.draft = draft ?? "";
  }

  factory UserProperties.fromJson(Map<String, dynamic> json) =>
      _$UserPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPropertiesToJson(this);
}
