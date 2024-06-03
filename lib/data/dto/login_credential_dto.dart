import 'package:json_annotation/json_annotation.dart';

part 'login_credential_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class LoginCredentialDto {
  String? type;

  LoginCredentialDto({this.type});

  factory LoginCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$LoginCredentialDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginCredentialDtoToJson(this);
}
