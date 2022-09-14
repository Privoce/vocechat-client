import 'package:json_annotation/json_annotation.dart';

part 'userdb_properties.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserDbProperties {
  UserDbProperties();

  factory UserDbProperties.fromJson(Map<String, dynamic> json) =>
      _$UserDbPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$UserDbPropertiesToJson(this);
}
