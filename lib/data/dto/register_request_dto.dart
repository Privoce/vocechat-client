import 'package:json_annotation/json_annotation.dart';

part 'register_request_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class RegisterRequestDto {
  String? magicToken;
  String? email;
  String? password;
  String? birthday;
  String? name;
  int? gender;
  String? language;
  String? device;
  String? deviceToken;

  RegisterRequestDto({
    this.magicToken,
    this.email,
    this.password,
    this.birthday,
    this.name,
    this.gender,
    this.language,
    this.device,
    this.deviceToken,
  });

  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestDtoToJson(this);
}
