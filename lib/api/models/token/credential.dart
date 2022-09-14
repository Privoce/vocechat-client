import 'package:json_annotation/json_annotation.dart';

part 'credential.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Credential {
  final String email;
  final String password;
  final String type;

  Credential(this.email, this.password, this.type);

  factory Credential.fromJson(Map<String, dynamic> json) =>
      _$CredentialFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialToJson(this);
}
