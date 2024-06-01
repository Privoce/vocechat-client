import 'package:json_annotation/json_annotation.dart';
import 'package:vocechat_client/data/dto/login_credential_dto.dart';
import 'package:vocechat_client/data/enum/login_credential_type.dart';

part 'login_credential_password_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class LoginCredentialPasswordDto extends LoginCredentialDto {
  final String? email;
  final String? password;

  LoginCredentialPasswordDto({
    this.email,
    this.password,
  }) : super(
          type: LoginCredentialType.password.name,
        );

  factory LoginCredentialPasswordDto.fromJson(Map<String, dynamic> json) =>
      _$LoginCredentialPasswordDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LoginCredentialPasswordDtoToJson(this);
}
